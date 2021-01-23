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

            dest_dir = "samples/{}/{}".format(samplename, progname_token)
            if not os.path.exists(dest_dir):
                os.makedirs(dest_dir)
                
            cmd = "cp {} {}".format(filename, dest_dir)
            subprocess.check_call(cmd, shell=True)
            print(cmd, file=sys.stderr)

    sys.exit(0)
                
    
if __name__=='__main__':
    main()


