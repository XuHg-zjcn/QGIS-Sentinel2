#open QGIS's python consol and copy-paste this file into it
import datetime
import bisect
import re
import glob

pattern_date = re.compile(r'S2._(\d{8})')

def name_to_pydt(name):
    date_str = pattern_date.match(name).group(1)
    date = datetime.datetime.strptime(date_str, "%Y%m%d")
    return date

#ref: https://gis.stackexchange.com/questions/102094/updating-contrast-enhancements-for-raster-layers-using-bandstatistics-in-pyqgis
#TODO: set gamma
def update_band_rgb(S2imgs, 
                    band_Red, band_Green, band_Blue,
                    percent_min=0.02, percent_max=0.99):
    for img in S2imgs:
        layer = img.layer()
        rend = layer.renderer()
        provider = layer.dataProvider()
        for vis, band in zip(['Red', 'Green', 'Blue'], [band_Red, band_Green, band_Blue]):
            getattr(rend, 'set'+vis+'Band')(band)
            Type = rend.dataType(band) #数据类型
            myEnhancement = QgsContrastEnhancement(Type)
            contrast_enhancement = QgsContrastEnhancement.StretchToMinimumMaximum 
            myEnhancement.setContrastEnhancementAlgorithm(contrast_enhancement,True)
            stats = provider.cumulativeCut(band,percent_min,percent_max,sampleSize=10000)
            myEnhancement.setMinimumValue(stats[0])
            myEnhancement.setMaximumValue(stats[1])
            myEnhancement.setContrastEnhancementAlgorithm(contrast_enhancement,True)
            getattr(rend,'set'+vis+'ContrastEnhancement')(myEnhancement)
        layer.triggerRepaint()

def setting_temporal(S2imgs):
    tp_pre = None
    date_pre = None
    for img in S2imgs:
        name = img.name()
        date = name_to_pydt(name)
        tp = img.layer().temporalProperties()
        if date_pre is not None:
            tp_pre.setMode(Qgis.RasterTemporalMode.FixedTemporalRange)
            tp_pre.setFixedTemporalRange(QgsDateTimeRange(QDateTime(date_pre), QDateTime(date)))
            tp_pre.setIsActive(True)
        date_pre = date
        tp_pre = tp

# ref: https://docs.qgis.org/3.40/en/docs/pyqgis_developer_cookbook/loadlayer.html#raster-layers
def update_from_directory(path, group):
    names = [x.name() for x in group.children()]
    dates = [name_to_pydt(n) for n in names]
    paths_vrt = glob.glob(os.path.join(path, '*/*.vrt'))
    for path_vrt in paths_vrt:
        name = os.path.basename(path_vrt).removesuffix('.vrt')
        if name in names:
            continue
        rlayer = QgsRasterLayer(path_vrt, name)
        if not rlayer.isValid():
            print(f"Layer {name} failed to load!")
        else:
            print(f"Layer {name} load sucussful")
        date = name_to_pydt(name)
        index = bisect.bisect(dates, date)
        names.insert(index, name)
        dates.insert(index, date)
        QgsProject.instance().addMapLayer(rlayer, False)
        group.insertChildNode(index, QgsLayerTreeLayer(rlayer))


root = QgsProject.instance().layerTreeRoot()
S2 = root.findGroup("Sentinel2")   # group name in QGIS project
update_from_directory('/mnt/3tsas/rs/uncompress/Sentinel2', S2)  # change to your directory to `batch.sh` output dir
S2imgs = S2.children()
update_band_rgb(S2imgs, 12, 8, 2)
setting_temporal(S2imgs)
