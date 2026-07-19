#include "SSHSettings.h"

#include "Log.h"

#include <QDir>
#include <QFile>
#include <QNetworkInterface>
#include <QProcess>
#include <QStandardPaths>
#include <QTemporaryFile>


namespace {

QString run_cmd(const QString& cmd, const QStringList& args, int timeout_ms = 10000)
{
    QProcess proc;
    proc.setProcessChannelMode(QProcess::SeparateChannels);
    proc.start(cmd, args);
    proc.waitForFinished(timeout_ms);
    return QString::fromLocal8Bit(proc.readAllStandardOutput()).trimmed();
}

QStringList run_cmd_lines(const QString& cmd, const QStringList& args, int timeout_ms = 10000)
{
    const QString output = run_cmd(cmd, args, timeout_ms);
    if (output.isEmpty())
        return {};
    return output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
}

QString keyCommentFromPath(const QString& path)
{
    QFile f(path + QStringLiteral(".pub"));
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    const QString line = QString::fromLocal8Bit(f.readLine()).trimmed();
    const QStringList parts = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
    return parts.size() >= 3 ? parts.at(2) : QString();
}

} // namespace


namespace model {

QString SSHSettings::runSudoCmd(const QString& cmd, const QStringList& args, int timeout_ms)
{
    if (m_sudo_password.isEmpty())
        return run_cmd(cmd, args, timeout_ms);

    // Create a temp script that echoes the password
    QTemporaryFile scriptFile;
    scriptFile.setAutoRemove(true);
    scriptFile.setFileTemplate(QDir::tempPath() + QStringLiteral("/pegasus_sudo_XXXXXX.sh"));
    if (!scriptFile.open()) {
        Log::warning(LOGMSG("Failed to create sudo helper script"));
        return {};
    }
    scriptFile.write((QStringLiteral("#!/bin/sh\necho '%1'\n").arg(m_sudo_password)).toLocal8Bit());
    scriptFile.close();

    QFile::setPermissions(scriptFile.fileName(),
        QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);

    QProcess proc;
    proc.setProcessChannelMode(QProcess::SeparateChannels);
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("DISPLAY"), QStringLiteral(":0"));
    env.insert(QStringLiteral("SSH_ASKPASS"), scriptFile.fileName());
    env.insert(QStringLiteral("ASKPASS"), scriptFile.fileName());
    proc.setProcessEnvironment(env);

    QStringList sudoArgs;
    sudoArgs << QStringLiteral("-A") << cmd << args;
    proc.start(QStringLiteral("sudo"), sudoArgs);
    proc.closeWriteChannel();
    proc.waitForFinished(timeout_ms);
    return QString::fromLocal8Bit(proc.readAllStandardOutput()).trimmed();
}

SSHSettings::SSHSettings(QObject* parent)
    : QObject(parent)
{
    m_user_name = QString::fromLocal8Bit(qgetenv("USER"));
    detectIpAddress();
    refreshStatus();

    m_refresh_timer.setInterval(5000);
    connect(&m_refresh_timer, &QTimer::timeout, this, &SSHSettings::refreshStatus);
    m_refresh_timer.start();
}

void SSHSettings::detectIpAddress()
{
    m_ip_address.clear();
    const auto interfaces = QNetworkInterface::allInterfaces();
    for (const QNetworkInterface& iface : interfaces) {
        if (iface.flags().testFlag(QNetworkInterface::IsUp)
            && iface.flags().testFlag(QNetworkInterface::IsRunning)
            && !iface.flags().testFlag(QNetworkInterface::IsLoopBack)) {
            const auto entries = iface.addressEntries();
            for (const QNetworkAddressEntry& entry : entries) {
                if (entry.ip().protocol() == QAbstractSocket::IPv4Protocol) {
                    m_ip_address = entry.ip().toString();
                    emit ipAddressChanged();
                    return;
                }
            }
        }
    }
    emit ipAddressChanged();
}

void SSHSettings::refreshStatus()
{
    detectIpAddress();

    // Check if sshd is installed
    const QString sshd_path = run_cmd(QStringLiteral("which"), {QStringLiteral("/usr/sbin/sshd")});
    m_ssh_installed = !sshd_path.isEmpty();
    emit sshInstalledChanged();

    if (!m_ssh_installed)
        return;

    // Check if sshd is running (avoid systemctl to prevent polkit prompts)
    const QString pid = run_cmd(QStringLiteral("pgrep"), {QStringLiteral("-x"), QStringLiteral("sshd")});
    const bool was_running = m_ssh_running;
    m_ssh_running = !pid.isEmpty();
    if (was_running != m_ssh_running)
        emit sshRunningChanged();

    // Get port from config
    const QString port_line = run_cmd(QStringLiteral("grep"), {
        QStringLiteral("^Port"),
        QStringLiteral("/etc/ssh/sshd_config")
    });
    if (!port_line.isEmpty()) {
        const QStringList parts = port_line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
        if (parts.size() >= 2) {
            bool ok = false;
            int port = parts.at(1).toInt(&ok);
            if (ok && port != m_ssh_port) {
                m_ssh_port = port;
                emit sshPortChanged();
            }
        }
    }

    // Refresh keys on first check
    if (m_keys.empty())
        refreshKeys();
}

void SSHSettings::refreshKeys()
{
    m_keys.clear();

    const QString home = QDir::homePath();
    const QString ssh_dir = home + QStringLiteral("/.ssh");

    // Common key types
    const QStringList types = {
        QStringLiteral("id_rsa"),
        QStringLiteral("id_ed25519"),
        QStringLiteral("id_ecdsa"),
        QStringLiteral("id_dsa"),
    };

    for (const QString& type : types) {
        const QString key_path = ssh_dir + QLatin1Char('/') + type;
        if (QFile::exists(key_path)) {
            QString comment = keyCommentFromPath(key_path);
            if (comment.isEmpty())
                comment = type;
            m_keys.push_back({ key_path, type, comment });
        }
    }

    emit keysChanged();
    Log::info(LOGMSG("Found %1 SSH keys").arg(m_keys.size()));
}

void SSHSettings::reloadKeys()
{
    refreshKeys();
}

void SSHSettings::install(const QString& password)
{
    if (m_installing || m_ssh_installed)
        return;

    m_installing = true;
    m_install_output.clear();
    emit installingChanged();
    emit installOutputChanged();

    m_install_proc = new QProcess(this);
    m_install_proc->setProcessChannelMode(QProcess::MergedChannels);

    connect(m_install_proc, &QProcess::readyReadStandardOutput, this, [this]() {
        m_install_output += QString::fromLocal8Bit(m_install_proc->readAllStandardOutput());
        emit installOutputChanged();
    });

    connect(m_install_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
        this, [this](int exitCode, QProcess::ExitStatus) {
        m_installing = false;
        emit installingChanged();

        const bool success = (exitCode == 0);
        m_install_output += success
            ? QStringLiteral("\n\nInstallation complete!")
            : QStringLiteral("\n\nInstallation failed (exit code: %1)").arg(exitCode);
        emit installOutputChanged();

        emit installResult(success, m_install_output);
        m_install_proc->deleteLater();
        m_install_proc = nullptr;

        refreshStatus();

        if (success) {
            refreshKeys();
        }
    });

    // Use sudo -A with askpass helper
    m_sudo_password = password;

    // Create temp helper script
    m_install_askpass = QStandardPaths::writableLocation(QStandardPaths::TempLocation)
        + QStringLiteral("/pegasus_ssh_askpass.sh");
    QFile script(m_install_askpass);
    if (script.open(QIODevice::WriteOnly | QIODevice::Text)) {
        script.write((QStringLiteral("#!/bin/sh\necho '%1'\n").arg(password)).toLocal8Bit());
        script.close();
        QFile::setPermissions(m_install_askpass,
            QFileDevice::ReadOwner | QFileDevice::WriteOwner | QFileDevice::ExeOwner);
    }

    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert(QStringLiteral("DISPLAY"), QStringLiteral(":0"));
    env.insert(QStringLiteral("SSH_ASKPASS"), m_install_askpass);
    env.insert(QStringLiteral("ASKPASS"), m_install_askpass);
    m_install_proc->setProcessEnvironment(env);

    m_install_proc->start(QStringLiteral("sudo"), {
        QStringLiteral("-A"),
        QStringLiteral("apt-get"),
        QStringLiteral("install"),
        QStringLiteral("-y"),
        QStringLiteral("openssh-server")
    });
    m_install_proc->closeWriteChannel();
}

void SSHSettings::addKey(const QString& type, const QString& comment)
{
    const QString home = QDir::homePath();
    const QString ssh_dir = home + QStringLiteral("/.ssh");
    const QString key_path = ssh_dir + QLatin1Char('/') + type;

    QDir().mkpath(ssh_dir);

    QStringList args;
    args << QStringLiteral("-t") << type
         << QStringLiteral("-f") << key_path;
    if (!comment.isEmpty())
        args << QStringLiteral("-C") << comment;

    const QString output = run_cmd(QStringLiteral("ssh-keygen"), args, 10000);
    Log::info(LOGMSG("Generated SSH key `%1`").arg(type));

    refreshKeys();
}

void SSHSettings::removeKey(int index)
{
    if (index < 0 || index >= static_cast<int>(m_keys.size()))
        return;

    const SshKey& key = m_keys.at(index);
    QFile::remove(key.path);
    QFile::remove(key.path + QStringLiteral(".pub"));
    Log::info(LOGMSG("Removed SSH key `%1`").arg(key.comment));

    refreshKeys();
}

QString SSHSettings::keyType(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_keys.size()))
        return m_keys.at(index).type;
    return {};
}

QString SSHSettings::keyComment(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_keys.size()))
        return m_keys.at(index).comment;
    return {};
}

QString SSHSettings::keyFingerprint(int index) const
{
    if (index < 0 || index >= static_cast<int>(m_keys.size()))
        return {};
    return run_cmd(QStringLiteral("ssh-keygen"), {
        QStringLiteral("-lf"), m_keys.at(index).path + QStringLiteral(".pub")
    }, 5000);
}

QString SSHSettings::keyPath(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_keys.size()))
        return m_keys.at(index).path;
    return {};
}

} // namespace model
