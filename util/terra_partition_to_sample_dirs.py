#!/usr/bin/env python

import sys, os, re
import subprocess

def main():
    usage = "\n\tusage: {} files.list.file progname_token\n\n".format(sys.argv[0])

    if len(sys.argv) < 3:
        print(usage, file=sys.stderr)
        sys.exit(1)

    files_list_file = sys.argv[1]
    progname_token = sys.argv[2]

    if not os.path.exists("samples"):
        os.makedirs("samples")

    with open(files_list_file) as fh:
        for filename in fh:
            filename = filename.rstrip()
            filename_pts = filename.split(".")

            samplename = filename_pts[0]
            if samplename in sample_conversions:
                samplename = sample_conversions[samplename]
                print("-renamed samplename to: {}".format(samplename))
            
            dest_dir = "samples/{}/{}".format(samplename, progname_token)
            if not os.path.exists(dest_dir):
                os.makedirs(dest_dir)
                
            cmd = "cp {} {}".format(filename, dest_dir)
            subprocess.check_call(cmd, shell=True)
            print(cmd, file=sys.stderr)

    sys.exit(0)
                

sample_conversions = {
    'G20476_DMS_454_2' : "G20476.DMS_454.2",
    "G20495_786-O_2" : "G20495.786-O.2",
    "G20498_KYSE-180_2" : "G20498.KYSE-180.2",
    "G20500_IGR-37_2" : "G20500.IGR-37.2",
    "G25214_MKN7_1" : "G25214.MKN7.1",
    "G25225_NCI-H522_1" : "G25225.NCI-H522.1",
    "G26175_A172_2" : "G26175.A172.2",
    "G26182_KMS-12-BM_2" : "G26182.KMS-12-BM.2",
    "G26199_LN-229_2" : "G26199.LN-229.2",
    "G26212_A-673_2" : "G26212.A-673.2",
    "G26216_KP-2_2" : "G26216.KP-2.2",
    "G26228_Hs_683_2" : "G26228.Hs_683.2",
    "G26236_NCI-H716_2" : "G26236.NCI-H716.2",
    "G26249_KMS-26_2" : "G26249.KMS-26.2",
    "G26253_KMS-34_2" : "G26253.KMS-34.2",
    "G26262_NCI-H889_2" : "G26262.NCI-H889.2",
    "G27214_PC-3_1" : "G27214.PC-3.1",
    "G27219_Panc_03_27_1" : "G27219.Panc_03.27.1",
    "G27233_A-498_1" : "G27233.A-498.1",
    "G27259_AN3_CA_1" : "G27259.AN3_CA.1",
    "G27280_TC-71_1" : "G27280.TC-71.1",
    "G27367_BFTC-909_1" : "G27367.BFTC-909.1",
    "G27376_COLO_792_1" : "G27376.COLO_792.1",
    "G27453_SNU-398_2" : "G27453.SNU-398.2",
    "G27463_SK-MEL-1_2" : "G27463.SK-MEL-1.2",
    "G27476_PK-59_2" : "G27476.PK-59.2",
    "G27479_SK-MEL-3_2" : "G27479.SK-MEL-3.2",
    "G27488_SNU-620_2" : "G27488.SNU-620.2",
    "G27516_SK-MEL-28_2" : "G27516.SK-MEL-28.2",
    "G27544_SF268_2" : "G27544.SF268.2",
    "G28011_KLE_1" : "G28011.KLE.1",
    "G28034_MDA-MB-361_1" : "G28034.MDA-MB-361.1",
    "G28045_KYSE-270_1" : "G28045.KYSE-270.1",
    "G28050_KMM-1_1" : "G28050.KMM-1.1",
    "G28054_KYSE-520_1" : "G28054.KYSE-520.1",
    "G28070_LN-18_1" : "G28070.LN-18.1",
    "G28072_MDA-MB-175-VII_1" : "G28072.MDA-MB-175-VII.1",
    "G28077_MG-63_1" : "G28077.MG-63.1",
    "G28081_JHH-7_1" : "G28081.JHH-7.1",
    "G28087_MDA-MB-436_1" : "G28087.MDA-MB-436.1",
    "G28535_OVTOKO_1" : "G28535.OVTOKO.1",
    "G28545_NUGC-2_1" : "G28545.NUGC-2.1",
    "G28575_OUMS-23_1" : "G28575.OUMS-23.1",
    "G28610_MHH-ES-1_1" : "G28610.MHH-ES-1.1",
    "G30594_UACC-893_1" : "G30594.UACC-893.1",
    "G30631_SU-DHL-10_1" : "G30631.SU-DHL-10.1",
    "G41663_OVISE_5" : "G41663.OVISE.5",
    "G41682_KYSE-510_5" : "G41682.KYSE-510.5",
    "G41706_RT4_5" : "G41706.RT4.5",
    "G41709_FaDu_5" : "G41709.FaDu.5",
    "G41710_SNU-16_5" : "G41710.SNU-16.5",
    "G41724_HGC-27_5" : "G41724.HGC-27.5" }

    
if __name__=='__main__':
    main()


