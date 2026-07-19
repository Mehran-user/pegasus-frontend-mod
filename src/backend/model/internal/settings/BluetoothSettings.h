#pragma once

#include "utils/QmlHelpers.h"

#include <QObject>
#include <QTimer>
#include <vector>


namespace model {

struct BluetoothDevice {
    QString name;
    QString mac;
    bool paired;
    bool connected;
};

class BluetoothSettings : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool btEnabled READ btEnabled WRITE setBtEnabled NOTIFY btEnabledChanged)
    Q_PROPERTY(bool hasBt READ hasBt CONSTANT)

public:
    explicit BluetoothSettings(QObject* parent = nullptr);

    bool btEnabled() const { return m_bt_enabled; }
    void setBtEnabled(bool enabled);

    bool hasBt() const { return m_has_bt; }

    Q_INVOKABLE void scan();
    Q_INVOKABLE void pair(const QString& mac);
    Q_INVOKABLE void connectDevice(const QString& mac);
    Q_INVOKABLE void disconnectDevice(const QString& mac);
    Q_INVOKABLE void removeDevice(const QString& mac);
    Q_INVOKABLE void disconnectAll();

    Q_INVOKABLE int deviceCount() const { return m_devices.size(); }
    Q_INVOKABLE QString deviceName(int index) const;
    Q_INVOKABLE QString deviceMac(int index) const;
    Q_INVOKABLE bool devicePaired(int index) const;
    Q_INVOKABLE bool deviceConnected(int index) const;

signals:
    void btEnabledChanged();
    void scanCompleted();
    void deviceAction(const QString& message);

private:
    bool m_bt_enabled = false;
    bool m_has_bt = false;
    std::vector<BluetoothDevice> m_devices;

    QTimer m_refresh_timer;

    void refreshStatus();
    void parseDevices();
};

} // namespace model
