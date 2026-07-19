#include "DisplaySettings.h"

#include "Log.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>


namespace {

struct ParsedMode {
    QString resolution;
    QString refresh_rate;
};

// xrandr output: "   1920x1080     59.98*+  60.00  "
// We extract the resolution and each refresh rate
std::vector<ParsedMode> parse_xrandr_line(const QString& line)
{
    std::vector<ParsedMode> modes;

    // Match resolution like "1920x1080"
    static const QRegularExpression re_res(QStringLiteral("(\\d+x\\d+)"));
    const auto res_match = re_res.match(line);
    if (!res_match.hasMatch())
        return modes;

    const QString resolution = res_match.captured(1);

    // Match all refresh rates: numbers like "59.98" optionally followed by * or +
    static const QRegularExpression re_rate(QStringLiteral("(\\d+\\.\\d+)\\*?\\+?"));
    auto rate_it = re_rate.globalMatch(line);

    while (rate_it.hasNext()) {
        const auto rate_match = rate_it.next();
        modes.push_back({ resolution, rate_match.captured(1) });
    }

    return modes;
}

QString run_cmd(const QString& cmd, const QStringList& args, int timeout_ms = 5000)
{
    QProcess proc;
    proc.start(cmd, args);
    proc.waitForFinished(timeout_ms);
    return QString::fromLocal8Bit(proc.readAllStandardOutput());
}

} // namespace


namespace model {

DisplaySettings::DisplaySettings(QObject* parent)
    : QObject(parent)
    , m_resolutions({})
    , m_refreshRates({})
    , m_rotations({
        QStringLiteral("normal"),
        QStringLiteral("left"),
        QStringLiteral("right"),
        QStringLiteral("inverted"),
    })
    , m_scaling({
        QStringLiteral("100%"),
        QStringLiteral("125%"),
        QStringLiteral("150%"),
        QStringLiteral("175%"),
        QStringLiteral("200%"),
        QStringLiteral("250%"),
        QStringLiteral("300%"),
    })
{
    detectDisplayServer();

    if (m_display_server == QStringLiteral("x11"))
        queryX11();
    else if (m_display_server == QStringLiteral("wayland"))
        queryWlrRandr();

    populateFromModes();
}

void DisplaySettings::detectDisplayServer()
{
    // Check QT_QPA_PLATFORM first
    const QString qpa = qgetenv("QT_QPA_PLATFORM");
    if (qpa.contains(QStringLiteral("wayland"))) {
        m_display_server = QStringLiteral("wayland");
        return;
    }

    // Check XDG_SESSION_TYPE
    const QString session_type = qgetenv("XDG_SESSION_TYPE");
    if (session_type == QStringLiteral("wayland")) {
        m_display_server = QStringLiteral("wayland");
        return;
    }

    // Check WAYLAND_DISPLAY
    if (!qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        m_display_server = QStringLiteral("wayland");
        return;
    }

    // Default to x11
    m_display_server = QStringLiteral("x11");
}

void DisplaySettings::queryX11()
{
    const QString output = run_cmd(QStringLiteral("xrandr"), {QStringLiteral("--query")});
    if (output.isEmpty()) {
        Log::warning(LOGMSG("Failed to query xrandr"));
        return;
    }

    const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    // Find first connected output
    for (const QString& line : lines) {
        if (!line.contains(QStringLiteral(" connected")))
            continue;

        // Extract output name (first word)
        m_output_name = line.section(QLatin1Char(' '), 0, 0);
        Log::info(LOGMSG("Display output: `%1`").arg(m_output_name));
        break;
    }

    if (m_output_name.isEmpty()) {
        Log::warning(LOGMSG("No connected display output found"));
        return;
    }

    // Parse modes for this output
    bool in_output = false;
    for (const QString& line : lines) {
        if (line.startsWith(m_output_name)) {
            in_output = true;
            continue;
        }
        if (in_output && !line.startsWith(QStringLiteral("   "))) {
            in_output = false;
            continue;
        }
        if (in_output) {
            auto modes = parse_xrandr_line(line);
            for (auto& mode : modes)
                m_modes.push_back({ mode.resolution, mode.refresh_rate, mode.resolution });
        }
    }

    // Get current rotation
    for (const QString& line : lines) {
        if (line.startsWith(m_output_name) && line.contains(QStringLiteral(" connected"))) {
            static const QRegularExpression re_rot(QStringLiteral("\\(([^)]+)"));
            const auto rot_match = re_rot.match(line);
            if (rot_match.hasMatch()) {
                const QString rotations_str = rot_match.captured(1);
                const QStringList rots = rotations_str.split(QLatin1Char(' '), Qt::SkipEmptyParts);
                if (!rots.isEmpty()) {
                    const QString current_rot = rots.first();
                    m_rotations.setCurrentByText(current_rot);
                }
            }
            break;
        }
    }
}

void DisplaySettings::queryWlrRandr()
{
    // Try wlr-randr first
    const QString json_output = run_cmd(QStringLiteral("wlr-randr"), {QStringLiteral("--json")});
    if (json_output.isEmpty()) {
        Log::warning(LOGMSG("wlr-randr not available or returned empty"));
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(json_output.toLocal8Bit());
    if (!doc.isArray())
        return;

    const QJsonArray outputs = doc.array();
    for (const QJsonValue& val : outputs) {
        const QJsonObject obj = val.toObject();
        if (!obj.value(QStringLiteral("Enabled")).toBool())
            continue;

        m_output_name = obj.value(QStringLiteral("Name")).toString();
        const QJsonArray modes = obj.value(QStringLiteral("Modes")).toArray();

        for (const QJsonValue& mode_val : modes) {
            const QJsonObject mode_obj = mode_val.toObject();
            const int w = mode_obj.value(QStringLiteral("Width")).toInt();
            const int h = mode_obj.value(QStringLiteral("Height")).toInt();
            const double rate = mode_obj.value(QStringLiteral("RefreshRate")).toDouble();

            const QString resolution = QStringLiteral("%1x%2").arg(w).arg(h);
            const QString rate_str = QString::number(rate, 'f', 2);

            m_modes.push_back({ resolution, rate_str, QStringLiteral("%1@%2").arg(resolution).arg(rate_str) });

            if (mode_obj.value(QStringLiteral("Current")).toBool()) {
                m_rotations.setCurrentByText(mode_obj.value(QStringLiteral("Transform")).toString());
            }
        }

        if (!m_output_name.isEmpty())
            break;
    }

    // Get current transform/rotation via wlr-randr
    const QString info = run_cmd(QStringLiteral("wlr-randr"), {});
    if (!info.isEmpty()) {
        static const QRegularExpression re_transform(QStringLiteral("Transform:\\s+(\\w+)"));
        const auto match = re_transform.match(info);
        if (match.hasMatch()) {
            const QString transform = match.captured(1);
            m_rotations.setCurrentByText(transform);
        }
    }
}

void DisplaySettings::populateFromModes()
{
    // Deduplicate resolutions
    QStringList resolutions;
    for (const auto& mode : m_modes) {
        if (!resolutions.contains(mode.resolution))
            resolutions.append(mode.resolution);
    }
    m_resolutions.setItems(resolutions);

    // Show refresh rates for the first resolution (or current)
    if (!resolutions.isEmpty()) {
        QStringList rates;
        const QString target_res = resolutions.first();
        for (const auto& mode : m_modes) {
            if (mode.resolution == target_res && !rates.contains(mode.refresh_rate))
                rates.append(mode.refresh_rate);
        }
        m_refreshRates.setItems(rates);
    }
}

void DisplaySettings::applyAll()
{
    if (m_output_name.isEmpty()) {
        emit applyFailed(QStringLiteral("No display output detected"));
        return;
    }

    const QString resolution = m_resolutions.currentText();
    const QString rate = m_refreshRates.currentText();
    const QString rotation = m_rotations.currentText();
    const QString scale_str = m_scaling.currentText();

    if (resolution.isEmpty()) {
        emit applyFailed(QStringLiteral("No resolution selected"));
        return;
    }

    // Parse scale percentage to float (e.g. "150%" -> "1.5")
    QString scale_factor;
    if (!scale_str.isEmpty()) {
        QString pct_str = scale_str;
        const int pct = pct_str.replace(QLatin1Char('%'), QString()).toInt();
        if (pct > 0)
            scale_factor = QString::number(pct / 100.0, 'f', 2);
    }

    Log::info(LOGMSG("Applying display: output=%1 mode=%2 rate=%3 rotation=%4 scale=%5")
        .arg(m_output_name, resolution, rate, rotation, scale_factor));

    if (m_display_server == QStringLiteral("x11")) {
        QStringList args;
        args << QStringLiteral("--output") << m_output_name
             << QStringLiteral("--mode") << resolution;

        if (!rate.isEmpty())
            args << QStringLiteral("--rate") << rate;

        if (!rotation.isEmpty())
            args << QStringLiteral("--rotate") << rotation;

        if (!scale_factor.isEmpty())
            args << QStringLiteral("--scale") << QStringLiteral("%1x%2").arg(scale_factor, scale_factor);

        QProcess::execute(QStringLiteral("xrandr"), args);
    } else {
        QStringList wlr_args;
        wlr_args << QStringLiteral("--output") << m_output_name
                 << QStringLiteral("--mode") << QStringLiteral("%1@%2").arg(resolution, rate);

        if (!rotation.isEmpty())
            wlr_args << QStringLiteral("--transform") << rotation;

        if (!scale_factor.isEmpty())
            wlr_args << QStringLiteral("--scale") << scale_factor;

        QProcess::execute(QStringLiteral("wlr-randr"), wlr_args);
    }
}

} // namespace model
