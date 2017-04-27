#ifndef DATAINPUT_H
#define DATAINPUT_H

#include <QMainWindow>

namespace Ui {
class DataInput;
}

class DataInput : public QMainWindow
{
    Q_OBJECT

public:
    explicit DataInput(QWidget *parent = 0);
    ~DataInput();

private slots:

    void on_chooseFile_clicked();

    void on_runButton_clicked();

private:
    Ui::DataInput *ui;
};

#endif // DATAINPUT_H
