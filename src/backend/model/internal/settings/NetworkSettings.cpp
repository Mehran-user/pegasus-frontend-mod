#include "NetworkSettings.h"

#include "Log.h"

#include <QProcess>


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

} // namespace


namespace model {

NetworkSettings::NetworkSettings(QObject* parent)
    : QObject(parent)
{
    // Check if nmcli is available
    const QString version = run_cmd(QStringLiteral("nmcli"), {QStringLiteral("--version")});
    if (version.isEmpty()) {
        Log::warning(LOGMSG("nmcli not found, network settings unavailable"));
        return;
    }

    // Check for WiFi hardware
    const QString radio_info = run_cmd(QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("WIFI"), QStringLiteral("general")});
    m_has_wifi = (radio_info == QStringLiteral("enabled") || radio_info == QStringLiteral("disabled"));

    refreshStatus();
    scan();

    // Auto-refresh every 15 seconds
    m_refresh_timer.setInterval(15000);
    connect(&m_refresh_timer, &QTimer::timeout, this, &NetworkSettings::refreshStatus);
    m_refresh_timer.start();
}

void NetworkSettings::refreshStatus()
{
    parseDeviceStatus();
}

void NetworkSettings::parseDeviceStatus()
{
    // Get WiFi state
    const QString wifi_state = run_cmd(QStringLiteral("nmcli"), {QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("WIFI"), QStringLiteral("general")});
    m_wifi_enabled = (wifi_state == QStringLiteral("enabled"));

    // Get active connection
    const QStringList active_lines = run_cmd_lines(QStringLiteral("nmcli"), {
        QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("NAME,TYPE,DEVICE"),
        QStringLiteral("connection"), QStringLiteral("show"), QStringLiteral("--active")
    });

    m_active_connection.clear();
    m_ip_address.clear();

    for (const QString& line : active_lines) {
        const QStringList parts = line.split(QLatin1Char(':'));
        if (parts.size() < 2)
            continue;
        const QString type = parts.value(1);
        if (type == QStringLiteral("802-11-wireless") || type == QStringLiteral("802-3-ethernet")) {
            m_active_connection = parts.first();
            break;
        }
    }

    // Get IP address for the active connection
    if (!m_active_connection.isEmpty()) {
        const QString ip_output = run_cmd(QStringLiteral("nmcli"), {
            QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("IP4.ADDRESS"),
            QStringLiteral("connection"), QStringLiteral("show"), m_active_connection
        });
        if (!ip_output.isEmpty()) {
            const QStringList ips = ip_output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            if (!ips.isEmpty()) {
                m_ip_address = ips.first().split(QLatin1Char('/')).first();
            }
        }
    }

    emit activeConnectionChanged();
}

void NetworkSettings::parseWifiList()
{
    m_networks.clear();

    const QStringList lines = run_cmd_lines(QStringLiteral("nmcli"), {
        QStringLiteral("-t"), QStringLiteral("-f"), QStringLiteral("SSID,SIGNAL,SECURITY"),
        QStringLiteral("device"), QStringLiteral("wifi"), QStringLiteral("list"),
        QStringLiteral("--rescan"), QStringLiteral("yes")
    });

    for (const QString& line : lines) {
        // Format: SSID:SIGNAL:SECURITY
        // Note: SSID can be empty (hidden network), and security field may contain colons
        const int first_colon = line.indexOf(QLatin1Char(':'));
        const int second_colon = line.indexOf(QLatin1Char(':'), first_colon + 1);

        if (first_colon < 0 || second_colon < 0)
            continue;

        const QString ssid = line.mid(0, first_colon);
        if (ssid.isEmpty())
            continue;

        bool ok = false;
        const int signal = line.mid(first_colon + 1, second_colon - first_colon - 1).toInt(&ok);
        if (!ok)
            continue;

        const QString security = line.mid(second_colon + 1);

        // Deduplicate (keep strongest signal)
        bool found = false;
        for (auto& net : m_networks) {
            if (net.ssid == ssid) {
                if (signal > net.signal) {
                    net.signal = signal;
                    net.security = security;
                }
                found = true;
                break;
            }
        }
        if (!found)
            m_networks.push_back({ ssid, signal, security });
    }

    // Sort by signal strength (strongest first)
    std::sort(m_networks.begin(), m_networks.end(),
        [](const WifiNetwork& a, const WifiNetwork& b) { return a.signal > b.signal; });

    Log::info(LOGMSG("Found %1 WiFi networks").arg(m_networks.size()));
    emit scanCompleted();
}

void NetworkSettings::scan()
{
    parseWifiList();
}

void NetworkSettings::setWifiEnabled(bool enabled)
{
    if (enabled == m_wifi_enabled)
        return;

    const QString arg = enabled ? QStringLiteral("on") : QStringLiteral("off");
    Log::info(LOGMSG("Setting WiFi to `%1`").arg(arg));
    run_cmd(QStringLiteral("nmcli"), {QStringLiteral("radio"), QStringLiteral("wifi"), arg});

    m_wifi_enabled = enabled;

    if (enabled) {
        // Wait a moment for WiFi to come up, then scan
        QTimer::singleShot(2000, this, &NetworkSettings::scan);
    } else {
        m_networks.clear();
        m_active_connection.clear();
        m_ip_address.clear();
        emit activeConnectionChanged();
    }

    emit wifiEnabledChanged();
}

void NetworkSettings::connectToNetwork(const QString& ssid, const QString& password)
{
    if (ssid.isEmpty())
        return;

    Log::info(LOGMSG("Connecting to WiFi `%1`").arg(ssid));

    QStringList args;
    args << QStringLiteral("device") << QStringLiteral("wifi")
         << QStringLiteral("connect") << ssid;

    if (!password.isEmpty())
        args << QStringLiteral("password") << password;

    const QString output = run_cmd(QStringLiteral("nmcli"), args, 30000);

    const bool success = output.contains(QStringLiteral("successfully"), Qt::CaseInsensitive);
    if (success) {
        Log::info(LOGMSG("Connected to `%1`").arg(ssid));
        QTimer::singleShot(1000, this, &NetworkSettings::refreshStatus);
    } else {
        Log::warning(LOGMSG("Failed to connect to `%1`: %2").arg(ssid, output));
    }

    emit connectionResult(success, success ? QStringLiteral("Connected") : output);
}

void NetworkSettings::disconnectCurrent()
{
    if (m_active_connection.isEmpty())
        return;

    Log::info(LOGMSG("Disconnecting from `%1`").arg(m_active_connection));
    run_cmd(QStringLiteral("nmcli"), {QStringLiteral("connection"), QStringLiteral("down"), m_active_connection});

    QTimer::singleShot(1000, this, &NetworkSettings::refreshStatus);
}

QString NetworkSettings::networkSsid(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_networks.size()))
        return m_networks.at(index).ssid;
    return {};
}

int NetworkSettings::networkSignal(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_networks.size()))
        return m_networks.at(index).signal;
    return 0;
}

QString NetworkSettings::networkSecurity(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_networks.size()))
        return m_networks.at(index).security;
    return {};
}

bool NetworkSettings::networkSecured(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_networks.size()))
        return !m_networks.at(index).security.isEmpty();
    return false;
}

} // namespace model
