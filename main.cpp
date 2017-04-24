#include "datainput.h"
#include <QApplication>

int main(int argc, char *argv[])
{
    QApplication a(argc, argv);
    DataInput w;
    w.setFixedSize(640,764); //maxwell set options
    w.show();

    return a.exec();
}
