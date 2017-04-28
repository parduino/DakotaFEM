#include "datainput.h"
#include "ui_datainput.h"
#include <QFileDialog>
#include <QMessageBox>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QDebug>
#include <QFileInfo>
#include <QProcess>
#include <QProcessEnvironment>
#include <QStringList>
#include <QRegExp>
#include <QStandardPaths>

DataInput::DataInput(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::DataInput)
{
    ui->setupUi(this);
    ui->numSamples->setValidator(new QIntValidator);
    ui->numSamples->setText(QString("10"));
}

DataInput::~DataInput()
{
    delete ui;
}



void DataInput::on_chooseFile_clicked()
{
    QString filename=QFileDialog::getOpenFileName(this,tr("Open File"),"C://", "All files (*.*)");
    ui-> filePath->setText(filename);
}

void DataInput::on_runButton_clicked()
{
    QJsonObject json;
    QString fileName=ui->filePath->text();
    QFileInfo fileInfo(fileName);

    json["mainInput"]=fileInfo.fileName();
    QString path = fileInfo.absolutePath();
    json["dir"]=path;

    int numSamples = ui->numSamples->text().toInt();

    QString method("method,\nsampling,\nsamples = ");
    method = method + QString::number(numSamples);
    method = method + QString(" \nseed = 98765,\nsample_type ");
    QString sampleType = ui->comboBox_uq->currentText();
    if (sampleType == QString("LHS"))
        sampleType = QString("lhs");
    else
        sampleType = QString("random");

    method = method + sampleType;
    json["method"]=method;

    QJsonArray rvArray;
    QJsonArray edpArray;

    // REDO when redo number of boxes
    int numRV = 3;
    QString rvNames[3];
    rvNames[0]=ui->rvName_1->text();
    rvNames[1]=ui->rvName_2->text();
    rvNames[2]=ui->rvName_3->text();

    QString rvTypes[3];
    rvTypes[0]=ui->rvDistribution_1->currentText();
    rvTypes[1]=ui->rvDistribution_2->currentText();
    rvTypes[2]=ui->rvDistribution_3->currentText();

    double rvMeans[3];
    rvMeans[0]=ui->rvMean_1->text().toDouble();
    rvMeans[1]=ui->rvMean_2->text().toDouble();
    rvMeans[2]=ui->rvMean_3->text().toDouble();

    double rvStdDev[3];
    rvStdDev[0]=ui->rvStdDev_1->text().toDouble();
    rvStdDev[1]=ui->rvStdDev_2->text().toDouble();
    rvStdDev[2]=ui->rvStdDev_3->text().toDouble();

    int numEDP = 3;
    QString edpNames[3];
    edpNames[0]=ui->edpName_1->text();
    edpNames[1]=ui->edpName_2->text();
    edpNames[2]=ui->edpName_3->text();
   // end REDO

    for (int i=0; i<numRV; i++) {
        if (!rvNames[i].isEmpty()) {
        QJsonObject rv;
        rv["name"]=rvNames[i];
        rv["type"]=rvTypes[i];
        rv["mean"]=rvMeans[i];
        rv["stdDev"]=rvStdDev[i];

        rvArray.append(rv);
        }
    }

    json["randomVariables"]=rvArray;

    for (int i=0; i<numEDP; i++) {
        if (!edpNames[i].isEmpty()) {
        QJsonObject edp;
        edp["name"]=edpNames[i];
        edpArray.append(edp);
        }
    }

    json["edp"]=edpArray;

    //
    // check for errors in input
    //


    bool error = false;
    QString errorMessage;

    if (fileName.isEmpty()) {
        error = true;
        errorMessage = errorMessage + QString("No Main Input File Provided\n");
    }

    if (rvArray.count() == 0) {
            error = true;
            errorMessage = errorMessage + QString("No Random Variables specified\n");
    }

    if (edpArray.count() == 0) {
        error = true;
        errorMessage = errorMessage + QString("No EDP names provided\n");
    }

    // if error, QMessageBox
    if (error == true) {
    QMessageBox messageBox;
    messageBox.critical(0,"Error",errorMessage);
    messageBox.setFixedSize(500,200);

    } else {

     //
     // do dakota
     //


     // write json to file
     QString jsonFileName = path + QString("/dakota.json");
     QJsonDocument doc(json);
     QFile jsonFile(jsonFileName);
     if(!jsonFile.open(QIODevice::WriteOnly)) {
         QMessageBox::information(0, "error", jsonFile.errorString());
         return;
     }
     //jsonFile.open(QFile::WriteOnly);

     jsonFile.write(doc.toJson());
     jsonFile.close();

     //
     // invoke the script to invoke & run dakota
     //

     QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
     //QStringList envlist = env.toStringList();
     //qDebug() << envlist;

     QProcess *proc = new QProcess();

     QString scriptToRun;
    if (QSysInfo::kernelType() == "linux") {

        scriptToRun = QString("/home/fmk/NHERI-SimCenter/DakotaFEM/localAPP/wrapper.sh");
        proc->setStandardErrorFile(QString("/home/fmk/err"));
        proc->setStandardOutputFile(QString("/home/fmk/out"));

    } else {

        scriptToRun = QString("/Users/fmk/NHERI/DakotaFEM/localAPP/wrapper.sh");
        proc->setStandardErrorFile("/Users/fmk/err");
        proc->setStandardOutputFile("/Users/fmk/out");
     }

     //proc->start("/home/fmk/NHERI-SimCenter/DakotaFEM/localApp/wrapper.sh", QStringList() << fileInfo.absolutePath() << fileInfo.fileName());
     proc->start(scriptToRun, QStringList() << fileInfo.absolutePath() << fileInfo.fileName());
     proc->waitForFinished(-1);

     //
     // once finished, parse dakota output file
     //
     QString dakotaData = path + QString("/dakota.tmp");
     QString dakotaTable = path + QString("/dakotaTab.out");
     QFile dakotaOut(dakotaData);
     dakotaOut.open(QFile::ReadOnly);
     dakotaOut.write(doc.toJson());
     dakotaOut.close();

     if(!dakotaOut.open(QIODevice::ReadOnly)) {
         QMessageBox::information(0, "error", dakotaOut.errorString());
         return;
     }

     QTextStream in(&dakotaOut);
     QStringList fields;
     while(!in.atEnd()) {
         QString line = in.readLine();;
         fields << line.split(" ");
        //model->appendRow(fields);
     }

    // qDebug() << fields;
     for (int i=0; i<numEDP; i++) {
         if (!edpNames[i].isEmpty()) {
         int index = fields.indexOf(QRegExp(edpNames[i]));
         QString mean = fields.at(index+2);
         QString stdDev = fields.at(index+4);

         // reformat numbers
         double meanVal = mean.toDouble();
         mean = QString::number(meanVal,'e',6);
         double stdDevVal = stdDev.toDouble();
         stdDev = QString::number(stdDevVal,'e',6);


         // REDO with above
         if (i==0) {
             ui->edpMean_1->setText(mean);
             ui->edpStdDev_1->setText(stdDev);
         } else if (i==1) {
             ui->edpMean_2->setText(mean);
             ui->edpStdDev_2->setText(stdDev);
         } else if (i==2) {
             ui->edpMean_3->setText(mean);
             ui->edpStdDev_3->setText(stdDev);
          } // REDO
         }
     }
     dakotaOut.close();

    }


    qDebug() << json;
}
