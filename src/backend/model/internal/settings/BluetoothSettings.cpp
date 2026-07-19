#include "BluetoothSettings.h"

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

BluetoothSettings::BluetoothSettings(QObject* parent)
    : QObject(parent)
{
    // Check if bluetoothctl is available
    const QString version = run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("--version")});
    if (version.isEmpty()) {
        Log::warning(LOGMSG("bluetoothctl not found, bluetooth settings unavailable"));
        return;
    }

    m_has_bt = true;
    refreshStatus();
    scan();

    // Auto-refresh every 10 seconds
    m_refresh_timer.setInterval(10000);
    connect(&m_refresh_timer, &QTimer::timeout, this, &BluetoothSettings::refreshStatus);
    m_refresh_timer.start();
}

void BluetoothSettings::refreshStatus()
{
    // Get power state
    const QString powered = run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("show")}, 5000);
    m_bt_enabled = powered.contains(QStringLiteral("Powered: yes"));

    parseDevices();

    emit btEnabledChanged();
}

void BluetoothSettings::parseDevices()
{
    m_devices.clear();

    const QStringList lines = run_cmd_lines(QStringLiteral("bluetoothctl"), {
        QStringLiteral("devices")
    });

    for (const QString& line : lines) {
        // Format: Device XX:XX:XX:XX:XX:XX Name
        if (!line.startsWith(QStringLiteral("Device ")))
            continue;

        const int first_space = line.indexOf(QLatin1Char(' '), 7);
        if (first_space < 0)
            continue;

        const QString mac = line.mid(7, first_space - 7);
        const QString name = line.mid(first_space + 1);

        // Check paired/connected info
        const QString info = run_cmd(QStringLiteral("bluetoothctl"), {
            QStringLiteral("info"), mac
        }, 3000);

        const bool paired = info.contains(QStringLiteral("Paired: yes"));
        const bool connected = info.contains(QStringLiteral("Connected: yes"));

        m_devices.push_back({ name, mac, paired, connected });
    }

    // Sort: connected first, then paired, then others
    std::sort(m_devices.begin(), m_devices.end(),
        [](const BluetoothDevice& a, const BluetoothDevice& b) {
            if (a.connected != b.connected) return a.connected;
            if (a.paired != b.paired) return a.paired;
            return a.name < b.name;
        });

    Log::info(LOGMSG("Found %1 bluetooth devices").arg(m_devices.size()));
    emit scanCompleted();
}

void BluetoothSettings::setBtEnabled(bool enabled)
{
    if (enabled == m_bt_enabled)
        return;

    const QString arg = enabled ? QStringLiteral("on") : QStringLiteral("off");
    Log::info(LOGMSG("Setting bluetooth to `%1`").arg(arg));
    run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("power"), arg});

    m_bt_enabled = enabled;

    if (enabled) {
        QTimer::singleShot(1000, this, &BluetoothSettings::scan);
    } else {
        m_devices.clear();
    }

    emit btEnabledChanged();
}

void BluetoothSettings::scan()
{
    if (!m_bt_enabled)
        return;

    run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("scan"), QStringLiteral("on")}, 5000);
    parseDevices();
}

void BluetoothSettings::pair(const QString& mac)
{
    Log::info(LOGMSG("Pairing with `%1`").arg(mac));
    const QString output = run_cmd(QStringLiteral("bluetoothctl"), {
        QStringLiteral("pair"), mac
    }, 20000);

    const bool success = !output.contains(QStringLiteral("failed"), Qt::CaseInsensitive)
                      && !output.contains(QStringLiteral("error"), Qt::CaseInsensitive);
    emit deviceAction(success
        ? QStringLiteral("Paired with %1").arg(mac)
        : QStringLiteral("Pairing failed: %1").arg(mac));

    QTimer::singleShot(1000, this, &BluetoothSettings::parseDevices);
}

void BluetoothSettings::connectDevice(const QString& mac)
{
    Log::info(LOGMSG("Connecting to `%1`").arg(mac));
    const QString output = run_cmd(QStringLiteral("bluetoothctl"), {
        QStringLiteral("connect"), mac
    }, 10000);

    const bool success = !output.contains(QStringLiteral("failed"), Qt::CaseInsensitive)
                      && !output.contains(QStringLiteral("error"), Qt::CaseInsensitive);
    emit deviceAction(success
        ? QStringLiteral("Connected to %1").arg(mac)
        : QStringLiteral("Connection failed: %1").arg(mac));

    QTimer::singleShot(1000, this, &BluetoothSettings::parseDevices);
}

void BluetoothSettings::disconnectDevice(const QString& mac)
{
    Log::info(LOGMSG("Disconnecting `%1`").arg(mac));
    run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("disconnect"), mac});

    QTimer::singleShot(1000, this, &BluetoothSettings::parseDevices);
}

void BluetoothSettings::removeDevice(const QString& mac)
{
    Log::info(LOGMSG("Removing `%1`").arg(mac));
    run_cmd(QStringLiteral("bluetoothctl"), {QStringLiteral("remove"), mac});

    QTimer::singleShot(1000, this, &BluetoothSettings::parseDevices);
}

QString BluetoothSettings::deviceName(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_devices.size()))
        return m_devices.at(index).name;
    return {};
}

QString BluetoothSettings::deviceMac(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_devices.size()))
        return m_devices.at(index).mac;
    return {};
}

bool BluetoothSettings::devicePaired(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_devices.size()))
        return m_devices.at(index).paired;
    return false;
}

bool BluetoothSettings::deviceConnected(int index) const
{
    if (index >= 0 && index < static_cast<int>(m_devices.size()))
        return m_devices.at(index).connected;
    return false;
}

} // namespace model
