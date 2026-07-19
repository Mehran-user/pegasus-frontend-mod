#pragma once

#include "StringListModel.h"
#include "utils/QmlHelpers.h"

#include <QObject>


namespace model {

class DisplaySettings : public QObject {
    Q_OBJECT
    QML_CONST_PROPERTY(model::StringListModel, resolutions)
    QML_CONST_PROPERTY(model::StringListModel, refreshRates)
    QML_CONST_PROPERTY(model::StringListModel, rotations)
    QML_CONST_PROPERTY(model::StringListModel, scaling)
    Q_PROPERTY(QString displayServer READ displayServer CONSTANT)
    Q_PROPERTY(QString outputName READ outputName CONSTANT)

public:
    explicit DisplaySettings(QObject* parent = nullptr);

    QString displayServer() const { return m_display_server; }
    QString outputName() const { return m_output_name; }

    Q_INVOKABLE void applyAll();

signals:
    void applyFailed(const QString& message);

private:
    QString m_display_server;
    QString m_output_name;

    struct ModeInfo {
        QString resolution;
        QString refresh_rate;
        QString full_mode; // e.g. "1920x1080" or "1920x1080@60.00"
    };

    std::vector<ModeInfo> m_modes;

    void detectDisplayServer();
    void queryX11();
    void queryWlrRandr();
    void populateFromModes();
};

} // namespace model
