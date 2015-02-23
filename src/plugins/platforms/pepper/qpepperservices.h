/****************************************************************************
**
** Copyright (C) 2014 Digia Plc
** All rights reserved.
** For any questions to Digia, please use contact form at http://qt.digia.com <http://qt.digia.com/>
**
** This file is part of the Qt Native Client platform plugin.
**
** No Commercial Usage
** This file contains pre-release code and may not be distributed.
** You may use this file in accordance with the terms and conditions
** contained in the Technology Preview License Agreement accompanying
** this package.
**
** If you have questions regarding the use of this file, please use
** contact form at http://qt.digia.com <http://qt.digia.com/>
**
****************************************************************************/

#ifndef QPEPPERSERVICES_H
#define QPEPPERSERVICES_H

#include <qpa/qplatformservices.h>

QT_BEGIN_NAMESPACE

class QPepperServices : public QPlatformServices
{
public:
    QPepperServices();
    bool openUrl(const QUrl &url) Q_DECL_OVERRIDE;
};

QT_END_NAMESPACE

#endif // QPEPPERSERVICES_H
