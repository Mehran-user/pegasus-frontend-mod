#pragma once

#include <QAbstractListModel>
#include <QStringList>


namespace model {

class StringListModel : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentChanged)
    Q_PROPERTY(QString currentText READ currentText NOTIFY currentChanged)
    Q_PROPERTY(int count READ rowCount CONSTANT)

public:
    explicit StringListModel(QStringList items, QObject* parent = nullptr);

    enum Roles {
        Name = Qt::UserRole + 1,
    };

    int rowCount(const QModelIndex& parent = QModelIndex()) const override;
    QVariant data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override { return m_role_names; }

    int currentIndex() const { return m_current_idx; }
    void setCurrentIndex(int idx);
    QString currentText() const;

    void setItems(const QStringList& items);
    void setCurrentByText(const QString& text);

signals:
    void currentChanged();

private:
    const QHash<int, QByteArray> m_role_names;
    QStringList m_items;
    int m_current_idx = 0;
};

} // namespace model
