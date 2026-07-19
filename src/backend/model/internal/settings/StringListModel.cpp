#include "StringListModel.h"


namespace model {

StringListModel::StringListModel(QStringList items, QObject* parent)
    : QAbstractListModel(parent)
    , m_role_names({{ Name, QByteArrayLiteral("name") }})
    , m_items(std::move(items))
{}

int StringListModel::rowCount(const QModelIndex& parent) const
{
    return parent.isValid() ? 0 : m_items.size();
}

QVariant StringListModel::data(const QModelIndex& index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.size())
        return {};
    if (role == Name)
        return m_items.at(index.row());
    return {};
}

void StringListModel::setCurrentIndex(int idx)
{
    if (idx < 0 || idx >= m_items.size())
        return;
    if (m_current_idx == idx)
        return;

    m_current_idx = idx;
    emit currentChanged();
}

QString StringListModel::currentText() const
{
    if (m_current_idx >= 0 && m_current_idx < m_items.size())
        return m_items.at(m_current_idx);
    return {};
}

void StringListModel::setItems(const QStringList& items)
{
    beginResetModel();
    m_items = items;
    m_current_idx = 0;
    endResetModel();
    emit currentChanged();
}

void StringListModel::setCurrentByText(const QString& text)
{
    const int idx = m_items.indexOf(text);
    if (idx >= 0)
        setCurrentIndex(idx);
}

} // namespace model
