import os
import sys
import re

degrees_per_mm = 0.5

def print_settings():
    for k, v in os.environ.items():
        if k.startswith("SLIC3R_"):
            print(k,v)

if __name__ == '__main__':
    start_temperature = os.environ["SLIC3R_TEMPERATURE"].split(",")[0]
    print("Starting with %s", start_temperature)
    with open(sys.argv[1], encoding="utf-8") as f:
        layer_re = re.compile(r"(.*Z)([\d|\.]*)(.*move to next layer.*)")
        output = []
        for l in f.readlines():
            m = layer_re.match(l)
            if m:
                layer_height = float(m.group(2))
                temperature = int(round(float(start_temperature) - degrees_per_mm * layer_height))
                print("Temperature at %f is %i" % (layer_height, temperature))
                output.append("M104 S %i; Set temperature\n" %(temperature))
            output.append(l)
    with open(sys.argv[1], encoding="utf-8", mode="w") as f:
        f.writelines(output)


