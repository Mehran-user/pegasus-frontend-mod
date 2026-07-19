// Pegasus Frontend
// Copyright (C) 2017  Mátyás Mustoha
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.


#pragma once

#include "AppSettings.h"
#include "KeyEditor.h"
#include "Locales.h"
#include "Themes.h"
#include "Providers.h"
#include "Timezones.h"
#include "DisplaySettings.h"
#include "NetworkSettings.h"
#include "BluetoothSettings.h"
#include "SSHSettings.h"
#include "utils/QmlHelpers.h"

#include <QObject>


namespace model {

/// Provides a settings interface for the frontend layer
class Settings : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool fullscreen
               READ fullscreen WRITE setFullscreen
               NOTIFY fullscreenChanged)
    Q_PROPERTY(bool mouseSupport
               READ mouseSupport WRITE setMouseSupport
               NOTIFY mouseSupportChanged)
    Q_PROPERTY(bool verifyFiles
               READ verifyFiles WRITE setVerifyFiles
               NOTIFY verifyFilesChanged)
    Q_PROPERTY(bool showMissingGames
               READ showMissingGames WRITE setShowMissingGames
               NOTIFY showMissingGamesChanged)
    Q_PROPERTY(QStringList gameDirs READ gameDirs NOTIFY gameDirsChanged)
    Q_PROPERTY(QStringList androidGrantedDirs READ androidGrantedDirs NOTIFY androidDirsChanged)
    Q_PROPERTY(QString splashLogo
               READ splashLogo WRITE setSplashLogo
               NOTIFY splashLogoChanged)
    Q_PROPERTY(bool networkTime
               READ networkTime WRITE setNetworkTime
               NOTIFY networkTimeChanged)
    Q_PROPERTY(bool use24hrClock
               READ use24hrClock WRITE setUse24hrClock
               NOTIFY use24hrClockChanged)
    Q_PROPERTY(bool showSeconds
               READ showSeconds WRITE setShowSeconds
               NOTIFY showSecondsChanged)

    QML_CONST_PROPERTY(model::KeyEditor, keyEditor)
    QML_CONST_PROPERTY(model::Locales, locales)
    QML_CONST_PROPERTY(model::Themes, themes)
    QML_CONST_PROPERTY(model::Providers, providers)
    QML_CONST_PROPERTY(model::Timezones, timezones)
    QML_CONST_PROPERTY(model::DisplaySettings, displaySettings)
    QML_CONST_PROPERTY(model::NetworkSettings, network)
    QML_CONST_PROPERTY(model::BluetoothSettings, bluetooth)
    QML_CONST_PROPERTY(model::SSHSettings, ssh)

public:
    explicit Settings(QObject* parent = nullptr);
    void postInit();

    bool fullscreen() const { return AppSettings::general.fullscreen; }
    void setFullscreen(bool);

    bool mouseSupport() const { return AppSettings::general.mouse_support; }
    void setMouseSupport(bool);

    bool verifyFiles() const { return AppSettings::general.verify_files; }
    void setVerifyFiles(bool);

    bool showMissingGames() const { return AppSettings::general.show_missing_games; }
    void setShowMissingGames(bool);

    QString splashLogo() const { return AppSettings::general.splash_logo; }
    void setSplashLogo(const QString&);

    bool networkTime() const { return AppSettings::general.network_time; }
    void setNetworkTime(bool);

    bool use24hrClock() const { return AppSettings::general.use_24hr_clock; }
    void setUse24hrClock(bool);

    bool showSeconds() const { return AppSettings::general.show_seconds; }
    void setShowSeconds(bool);

    QStringList gameDirs() const;
    Q_INVOKABLE void addGameDir(const QString&);
    Q_INVOKABLE void removeGameDirs(const QVariantList&);

    QStringList androidGrantedDirs() const;
    Q_INVOKABLE void requestAndroidDir();

    Q_INVOKABLE void reloadProviders();

signals:
    void fullscreenChanged();
    void mouseSupportChanged();
    void verifyFilesChanged();
    void showMissingGamesChanged();
    void splashLogoChanged();
    void networkTimeChanged();
    void use24hrClockChanged();
    void showSecondsChanged();
    void gameDirsChanged();
    void androidDirsChanged();
    void providerReloadingRequested();
};

} // namespace model
