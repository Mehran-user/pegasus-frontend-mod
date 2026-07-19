#pragma once

#include "utils/QmlHelpers.h"

#include <QObject>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <vector>


namespace model {

struct SshKey {
    QString path;
    QString type;
    QString comment;
};

class SSHSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool sshInstalled READ sshInstalled NOTIFY sshInstalledChanged)
    Q_PROPERTY(bool sshRunning READ sshRunning NOTIFY sshRunningChanged)
    Q_PROPERTY(bool installing READ installing NOTIFY installingChanged)
    Q_PROPERTY(QString installOutput READ installOutput NOTIFY installOutputChanged)
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY ipAddressChanged)
    Q_PROPERTY(int sshPort READ sshPort NOTIFY sshPortChanged)
    Q_PROPERTY(QString userName READ userName CONSTANT)

public:
    explicit SSHSettings(QObject* parent = nullptr);

    bool sshInstalled() const { return m_ssh_installed; }
    bool sshRunning() const { return m_ssh_running; }
    bool installing() const { return m_installing; }
    QString installOutput() const { return m_install_output; }
    QString ipAddress() const { return m_ip_address; }
    int sshPort() const { return m_ssh_port; }
    QString userName() const { return m_user_name; }

    Q_INVOKABLE void install(const QString& password);

    Q_INVOKABLE int keyCount() const { return m_keys.size(); }
    Q_INVOKABLE QString keyType(int index) const;
    Q_INVOKABLE QString keyComment(int index) const;
    Q_INVOKABLE QString keyFingerprint(int index) const;
    Q_INVOKABLE QString keyPath(int index) const;
    Q_INVOKABLE void addKey(const QString& type, const QString& comment);
    Q_INVOKABLE void removeKey(int index);
    Q_INVOKABLE void reloadKeys();

signals:
    void sshInstalledChanged();
    void sshRunningChanged();
    void installingChanged();
    void installOutputChanged();
    void ipAddressChanged();
    void sshPortChanged();
    void keysChanged();
    void installResult(bool success, const QString& message);

private:
    bool m_ssh_installed = false;
    bool m_ssh_running = false;
    bool m_installing = false;
    QString m_install_output;
    QString m_ip_address;
    QString m_user_name;
    int m_ssh_port = 22;

    std::vector<SshKey> m_keys;
    QProcess* m_install_proc = nullptr;
    QTimer m_refresh_timer;
    QString m_sudo_password;
    QString m_install_askpass;

    void refreshStatus();
    void refreshKeys();
    void detectIpAddress();
    QString runSudoCmd(const QString& cmd, const QStringList& args, int timeout_ms = 10000);
};

} // namespace model
