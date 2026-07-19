#pragma once

#include "utils/MoveOnly.h"

#include <QAbstractListModel>


namespace model {

class Timezones : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY timezoneChanged)
    Q_PROPERTY(QString currentTimezone READ currentTimezone NOTIFY timezoneChanged)

public:
    explicit Timezones(QObject* parent = nullptr);

    enum Roles {
        Name = Qt::UserRole + 1,
    };

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override { return m_role_names; }

    int currentIndex() const { return static_cast<int>(m_current_idx); }
    void setCurrentIndex(int);
    QString currentTimezone() const;

Q_INVOKABLE void applyTimezone();
Q_INVOKABLE void applyNtp(bool enabled);

signals:
    void timezoneChanged();

private:
    const QHash<int, QByteArray> m_role_names;
    std::vector<QString> m_timezones;

    size_t m_current_idx;

    bool select_timezone(const QString&);
    void load_system_timezone();
    static std::vector<QString> read_available_timezones();
};
} // namespace model
