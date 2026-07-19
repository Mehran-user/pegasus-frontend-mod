#include "Timezones.h"

#include "AppSettings.h"
#include "Log.h"

#include <QDateTime>
#include <QProcess>
#include <QTimeZone>


namespace {

std::vector<QString> read_available_timezones()
{
    QProcess proc;
    proc.start(QStringLiteral("timedatectl"), {QStringLiteral("list-timezones")});
    proc.waitForFinished(5000);

    std::vector<QString> result;
    if (proc.exitCode() != 0) {
        result.push_back(QStringLiteral("UTC"));
        return result;
    }

    const QByteArray output = proc.readAllStandardOutput();
    const QStringList lines = QString::fromLocal8Bit(output).split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    result.reserve(lines.size());
    for (const QString& line : lines)
        result.emplace_back(line.trimmed());

    if (result.empty())
        result.push_back(QStringLiteral("UTC"));

    return result;
}

} // namespace


namespace model {

Timezones::Timezones(QObject* parent)
    : QAbstractListModel(parent)
    , m_role_names({{ Name, QByteArrayLiteral("name") }})
    , m_timezones(read_available_timezones())
    , m_current_idx(0)
{
    load_system_timezone();
}

std::vector<QString> Timezones::read_available_timezones()
{
    return ::read_available_timezones();
}

void Timezones::load_system_timezone()
{
    const QString current = AppSettings::general.timezone;
    if (!current.isEmpty() && select_timezone(current))
        return;

    // Try to detect from system
    const QString sys_tz = QDateTime::currentDateTime().timeZone().id();
    if (!sys_tz.isEmpty() && select_timezone(sys_tz))
        return;

    // Fall back to UTC
    select_timezone(QStringLiteral("UTC"));
}

bool Timezones::select_timezone(const QString& tz)
{
    for (size_t i = 0; i < m_timezones.size(); i++) {
        if (m_timezones[i] == tz) {
            if (m_current_idx == i)
                return true;
            m_current_idx = i;
            return true;
        }
    }
    return false;
}

int Timezones::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : static_cast<int>(m_timezones.size());
}

QVariant Timezones::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= static_cast<int>(m_timezones.size()))
        return {};

    if (role == Name)
        return m_timezones.at(index.row());

    return {};
}

QString Timezones::currentTimezone() const
{
    if (m_current_idx < m_timezones.size())
        return m_timezones.at(m_current_idx);
    return QStringLiteral("UTC");
}

void Timezones::setCurrentIndex(int new_idx)
{
    if (new_idx < 0 || new_idx >= static_cast<int>(m_timezones.size()))
        return;
    if (static_cast<size_t>(new_idx) == m_current_idx)
        return;

    m_current_idx = new_idx;
    AppSettings::general.timezone = m_timezones.at(m_current_idx);
    AppSettings::save_config();

    applyTimezone();

    emit timezoneChanged();
}

void Timezones::applyTimezone()
{
    if (m_current_idx >= m_timezones.size())
        return;

    const QString tz = m_timezones.at(m_current_idx);
    Log::info(LOGMSG("Setting timezone to `%1`").arg(tz));

    QProcess::execute(QStringLiteral("timedatectl"), {QStringLiteral("set-timezone"), tz});
}

void Timezones::applyNtp(bool enabled)
{
    Log::info(LOGMSG("Setting network time to `%1`").arg(enabled ? "enabled" : "disabled"));
    QProcess::execute(QStringLiteral("timedatectl"), {QStringLiteral("set-ntp"), enabled ? QStringLiteral("true") : QStringLiteral("false")});
}

} // namespace model
