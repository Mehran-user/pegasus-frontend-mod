#pragma once

#include "StringListModel.h"
#include "utils/QmlHelpers.h"

#include <QObject>
#include <QTimer>


namespace model {

struct WifiNetwork {
    QString ssid;
    int signal;    // 0-100
    QString security;
};

class NetworkSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled WRITE setWifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(bool hasWifi READ hasWifi CONSTANT)
    Q_PROPERTY(QString activeConnection READ activeConnection NOTIFY activeConnectionChanged)
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY activeConnectionChanged)

public:
    explicit NetworkSettings(QObject* parent = nullptr);

    bool wifiEnabled() const { return m_wifi_enabled; }
    void setWifiEnabled(bool enabled);

    bool hasWifi() const { return m_has_wifi; }
    QString activeConnection() const { return m_active_connection; }
    QString ipAddress() const { return m_ip_address; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE void connectToNetwork(const QString& ssid, const QString& password);
    Q_INVOKABLE void disconnectCurrent();

    Q_INVOKABLE int networkCount() const { return m_networks.size(); }
    Q_INVOKABLE QString networkSsid(int index) const;
    Q_INVOKABLE int networkSignal(int index) const;
    Q_INVOKABLE QString networkSecurity(int index) const;
    Q_INVOKABLE bool networkSecured(int index) const;

signals:
    void wifiEnabledChanged();
    void activeConnectionChanged();
    void scanCompleted();
    void connectionResult(bool success, const QString& message);

private:
    bool m_wifi_enabled = false;
    bool m_has_wifi = false;
    QString m_active_connection;
    QString m_ip_address;
    std::vector<WifiNetwork> m_networks;

    QTimer m_refresh_timer;

    void refreshStatus();
    void parseDeviceStatus();
    void parseWifiList();
};

} // namespace model
