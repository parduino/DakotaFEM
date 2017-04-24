#include "datainput.h"
#include "ui_datainput.h"
#include <QFileDialog>
#include <QMessageBox>

DataInput::DataInput(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::DataInput)
{
    ui->setupUi(this);


}

DataInput::~DataInput()
{
    delete ui;
}

void DataInput::on_pushButton_2_clicked()
{
    QString test1 = ui->variableName_1->text(); //first line edit make text
    ui-> variableName_2->setText(test1); //Test set text
    QString test2 = ui->comboBox_program ->currentText(); //retrieve the text from the combo
    ui ->variableName_3->setText(test2); //Test set text

}

void DataInput::on_chooseFile_clicked()
{
    QString filename=QFileDialog::getOpenFileName(this,tr("Open File"),"C://", "All files (*.*)");
    ui-> filePath->setText(filename);

}
