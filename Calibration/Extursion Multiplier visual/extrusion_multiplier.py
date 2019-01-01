from __future__ import print_function
import argparse
from math import pi, pow

def main():
    parser = argparse.ArgumentParser(description="Generate gcode to tune the extrusion multiplier",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument("--output", required=True, type=argparse.FileType("w"), default=argparse.SUPPRESS,
                        help="The output file")
    parser.add_argument("--layer_height", required=True, type=float, default=argparse.SUPPRESS,
                        help="The layer height in mm")
    parser.add_argument("--filament_diameter", required=True, type=float, default=argparse.SUPPRESS,
                        help="The diameter of the filament in mm")
    parser.add_argument("--line_width", required=True, type=float, default=argparse.SUPPRESS,
                        help="The line width in mm")
    parser.add_argument("--start_gcode", required=True, type=argparse.FileType("r"), default=argparse.SUPPRESS,
                        help="The start gcode. You can use the following variables {print_temperature}, {bed_temperature}")
    parser.add_argument("--end_gcode", required=True, type=argparse.FileType("r"), default=argparse.SUPPRESS,
                        help="The end gcode")
    parser.add_argument("--print_temperature", required=True, type=int, default=argparse.SUPPRESS,
                        help="The print temperature")
    parser.add_argument("--bed_temperature", required=True, type=int, default=argparse.SUPPRESS,
                        help="The bed temperature")
    parser.add_argument("--flow", required=False, type=float, default=100,
                        help="The middle of the flow range to use. Set if you want to verify it, or test the first layer.")
    parser.add_argument("--range", required=False, type=float, default=10.0,
                        help="How many percent below and above the set flow to test")
    parser.add_argument("--test_width", required=False, type=float, default=20,
                        help="The width of the test in mm")
    parser.add_argument("--test_layers", required=False, type=int, default=5,
                        help="The number of layers to print")
    parser.add_argument("--speed", required=False, type=float, default=30.0,
                        help="Print speed in mm/s")
    parser.add_argument("--first_layer_speed", required=False, type=float, default=argparse.SUPPRESS,
                        help="If specified the first layer speed in mm/s. If not the first layer speed will be half the normal speed")
    parser.add_argument("--step", required=False, type=float, default=0.5,
                        help="How much the flow changes for each line, in percent")
    parser.add_argument("--x", required=False, type=float, default=100,
                        help="The x position of the part")
    parser.add_argument("--y", required=False, type=float, default=100,
                        help="The y position of the part")
    args = parser.parse_args()

    first_layer_speed = args.first_layer_speed if "first_layer_speed" in args else args.speed * 0.5
    start_flow = (args.flow - args.range) * 0.01
    num_lines = round(args.range * 2 / args.step)
    flows = [start_flow + x*args.step*0.01 for x in range(num_lines + 1)]

    width = num_lines * args.line_width
    height = args.test_width

    z = args.layer_height
    x = args.x - width / 2
    y = args.y - height / 2
    ys = (y, y + height)
    y_index = 0
    x_step = args.line_width
    e_pos = 0

    filament_area = pi * pow((args.filament_diameter / 2), 2)
    extrusion_area = args.layer_height * args.line_width

    start_gcode = args.start_gcode.read();
    start_gcode = start_gcode.replace("{print_temperature}", str(args.print_temperature))
    start_gcode = start_gcode.replace("{bed_temperature}", str(args.bed_temperature))
    if start_gcode[-1] != "\n":
        start_gcode = start_gcode + "\n"
    args.output.write(start_gcode)

    args.output.write("G21 ;metric values\n")
    args.output.write("G90 ;absolute positioning\n")
    args.output.write("M82 ;set extruder to absolute mode\n")
    args.output.write("G92 E0 ;reset extruder\n")

    speed = int(first_layer_speed * 60)
    for layer in range(args.test_layers):
        args.output.write("G1 F%d\n" % (speed))
        args.output.write("G1 Z%f\n" % z)
        # Use full flow for the first layer, if we have more than one
        if args.test_layers > 1 and layer == 0:
            used_flows = [1.0] * len(flows)
        else:
            used_flows = flows if x_step > 0 else reversed(flows)
        for flow in used_flows:
            area = extrusion_area * flow
            extrusion_ratio = area / filament_area
            args.output.write("G1 X%f Y%f\n" % (x, ys[y_index]))
            y_index = (y_index + 1) % 2
            e_pos += extrusion_ratio * height
            args.output.write("G1 X%f Y%f E%f\n" % (x, ys[y_index], e_pos))
            x += x_step
        z += args.layer_height
        x -= x_step
        x_step = -x_step
        speed = int(args.speed * 60)
    args.output.write(args.end_gcode.read())



if __name__ == "__main__":
    # execute only if run as a script
    main()


