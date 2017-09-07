/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Copyright (C) 2016 Pelagicore AG
** Copyright (C) 2015 Pier Luigi Fiorini <pierluigi.fiorini@gmail.com>
** Contact: https://www.qt.io/licensing/
**
** This file is part of the plugins of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:LGPL$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU Lesser General Public License Usage
** Alternatively, this file may be used under the terms of the GNU Lesser
** General Public License version 3 as published by the Free Software
** Foundation and appearing in the file LICENSE.LGPL3 included in the
** packaging of this file. Please review the following information to
** ensure the GNU Lesser General Public License version 3 requirements
** will be met: https://www.gnu.org/licenses/lgpl-3.0.html.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 2.0 or (at your option) the GNU General
** Public license version 3 or any later version approved by the KDE Free
** Qt Foundation. The licenses are as published by the Free Software
** Foundation and appearing in the file LICENSE.GPL2 and LICENSE.GPL3
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-2.0.html and
** https://www.gnu.org/licenses/gpl-3.0.html.
**
** $QT_END_LICENSE$
**
****************************************************************************/

#ifndef QKMSDEVICE_P_H
#define QKMSDEVICE_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

#include <qpa/qplatformscreen.h>
#include <QtCore/QMap>
#include <QtCore/QVariant>

#include <xf86drm.h>
#include <xf86drmMode.h>
#include <drm_fourcc.h>

QT_BEGIN_NAMESPACE

class QKmsDevice;

class QKmsScreenConfig
{
public:
    enum VirtualDesktopLayout {
        VirtualDesktopLayoutHorizontal,
        VirtualDesktopLayoutVertical
    };

    QKmsScreenConfig();

    QString devicePath() const { return m_devicePath; }

    bool headless() const { return m_headless; }
    QSize headlessSize() const { return m_headlessSize; }
    bool hwCursor() const { return m_hwCursor; }
    bool separateScreens() const { return m_separateScreens; }
    bool supportsPBuffers() const { return m_pbuffers; }
    VirtualDesktopLayout virtualDesktopLayout() const { return m_virtualDesktopLayout; }

    QMap<QString, QVariantMap> outputSettings() const { return m_outputSettings; }

private:
    void loadConfig();

    QString m_devicePath;
    bool m_headless;
    QSize m_headlessSize;
    bool m_hwCursor;
    bool m_separateScreens;
    bool m_pbuffers;
    VirtualDesktopLayout m_virtualDesktopLayout;
    QMap<QString, QVariantMap> m_outputSettings;
};

struct QKmsOutput
{
    QString name;
    uint32_t connector_id = 0;
    uint32_t crtc_index = 0;
    uint32_t crtc_id = 0;
    QSizeF physical_size;
    int preferred_mode = -1; // index of preferred mode in list below
    int mode = -1; // index of selected mode in list below
    bool mode_set = false;
    drmModeCrtcPtr saved_crtc = nullptr;
    QList<drmModeModeInfo> modes;
    int subpixel = DRM_MODE_SUBPIXEL_UNKNOWN;
    drmModePropertyPtr dpms_prop = nullptr;
    drmModePropertyBlobPtr edid_blob = nullptr;
    bool wants_forced_plane = false;
    uint32_t forced_plane_id = 0;
    bool forced_plane_set = false;
    uint32_t drm_format = DRM_FORMAT_XRGB8888;
    QString clone_source;

    void restoreMode(QKmsDevice *device);
    void cleanup(QKmsDevice *device);
    QPlatformScreen::SubpixelAntialiasingType subpixelAntialiasingTypeHint() const;
    void setPowerState(QKmsDevice *device, QPlatformScreen::PowerState state);
};

class QKmsDevice
{
public:
    struct ScreenInfo {
        int virtualIndex = 0;
        QPoint virtualPos;
        bool isPrimary = false;
        QKmsOutput output;
    };

    QKmsDevice(QKmsScreenConfig *screenConfig, const QString &path = QString());
    virtual ~QKmsDevice();

    virtual bool open() = 0;
    virtual void close() = 0;
    virtual void *nativeDisplay() const = 0;

    void createScreens();

    int fd() const;
    QString devicePath() const;

    QKmsScreenConfig *screenConfig() const;

protected:
    virtual QPlatformScreen *createScreen(const QKmsOutput &output) = 0;
    virtual QPlatformScreen *createHeadlessScreen();
    virtual void registerScreenCloning(QPlatformScreen *screen,
                                       QPlatformScreen *screenThisScreenClones,
                                       const QVector<QPlatformScreen *> &screensCloningThisScreen);
    virtual void registerScreen(QPlatformScreen *screen,
                                bool isPrimary,
                                const QPoint &virtualPos,
                                const QList<QPlatformScreen *> &virtualSiblings) = 0;

    void setFd(int fd);
    int crtcForConnector(drmModeResPtr resources, drmModeConnectorPtr connector);
    QPlatformScreen *createScreenForConnector(drmModeResPtr resources,
                                              drmModeConnectorPtr connector,
                                              ScreenInfo *vinfo);
    drmModePropertyPtr connectorProperty(drmModeConnectorPtr connector, const QByteArray &name);
    drmModePropertyBlobPtr connectorPropertyBlob(drmModeConnectorPtr connector, const QByteArray &name);

    QKmsScreenConfig *m_screenConfig;
    QString m_path;
    int m_dri_fd;

    quint32 m_crtc_allocator;

private:
    Q_DISABLE_COPY(QKmsDevice)
};

QT_END_NAMESPACE

#endif
