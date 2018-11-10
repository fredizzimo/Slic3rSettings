X=+0; Y=+1; Z=+2;

/* [General] */
// temperature of the first lowest block
start_temp = 220;
// temperature of the last highest block
end_temp = 175;
// change in temperature between successively printed blocks
temp_step = 5;

layer_height = 0.2;


/* [Detail Geometry] */
// dimensions of the base plate
base = [46, 14, 8*layer_height];
// dimensions of the pedestal under a tower block
pedestal = [6, 6, 5*layer_height];
// dimensions of the tower block
block = [8, 8, 30*layer_height];
// X spacing between the towers
tower_x_distance = 16*2;
// left (X-) overhang size
overhang_l_x = 3;
// right (X+) overhang size
overhang_r_x = 5;
// top of the bridge relative to the top of the block
bridge_z_top = 0;
// thickness of the bridge
bridge_z = 8*layer_height;
sphere_radius = overhang_r_x / 2 - 0.5;
// top of the overhang relative to the top of the block
overhang_z_top = ceil(-sphere_radius / layer_height) * layer_height;
// height of the overhang
overhang_z = 15*layer_height;
// gap between the bridge and the left (X-) tower
bridge_l_gap = 1;
// gap between the bridge and the right (X+) tower
bridge_r_gap = 3;
bridge_y_front = -block[Y]/2;
bridge_y = block[Y]/2;
cone_bridge_gap = 5 * layer_height;
chimney_bridge_gap = 10 * layer_height;
chimney_top_height = 5 * layer_height;
cone_radius = 1.5;
chimney_radius = cone_radius;
chimney_hole_radius = 1;
chimney_top_radius = 1.9;
// embossing depth of the text
text_depth = 1;
// font used for the text
text_font = "Helvetica:style=Bold";
// text ascent relative to the width of the tower block
text_ascent = 0.4;


module Tower(x, overhang, gap, addpoint, label)
    translate([x,0,0])
    scale([x<=0 ? 1 : -1, 1, 1])
{
    z1 = 0;
    translate([0,0,z1 + pedestal[Z]/2]) cube(pedestal, true);
    z2 = z1 + pedestal[Z];
    label = label ? str(label) : "0";
    difference() 
    {
        translate([0,0,z2 + block[Z]/2]) cube(block, true);
        translate([0, -block[Y]/2+text_depth-0.001, z2 + block[Z]/2])
        rotate([90,0,0])
        linear_extrude(text_depth)   
        if (addpoint==0){
            text(label, size = block[X] * text_ascent, 
                 valign = "center", halign = "center",
                 font = text_font);
        }
    }
    
    overhang_pts = [[0,0],[0,-overhang_z],[overhang,0]];
    z3 = z2 + block[Z];
    z4 = z3 + overhang_z_top;
    translate([block[X]/2, block[Y]/2, z4])
        rotate([90,0,0])
        linear_extrude(block[Y])
        polygon(points=overhang_pts);
    
    // make overhang right side:
    if (addpoint==1)
    {   // overhang
        translate([-block[X]/2, -block[Y]/2, z4])
            rotate([90,0,180])
            linear_extrude(block[Y])
            polygon(points=overhang_pts);
        
        // pointy cone
        translate([block[X]/2 + gap + overhang - gap + cone_radius, bridge_y_front + bridge_y / 2, bridge_z_top])
        cylinder($fn = 50, h=block[Z] - cone_bridge_gap, r1=cone_radius, r2=0, center=false);  

		
		translate([-block[X]/2 - overhang_r_x / 2 , 0, -sphere_radius]) 
		difference()
		{
			translate([0, 0, z3]) 
			sphere($fn = 50, r=sphere_radius);
			translate([0, 0, z4])
			cube(sphere_radius * 2, center=true);
		}
    }
    else
    {
        // chimney 
        translate([block[X]/2 + gap + overhang - gap + cone_radius, bridge_y_front + bridge_y / 2, bridge_z_top])
		{
			difference()
			{
				union()
				{
					chimney_height = block[Z] - chimney_bridge_gap;
					cylinder($fn = 50, h=chimney_height, r1=chimney_radius, r2=chimney_radius, center=false);  
					translate([0, 0, chimney_height - chimney_top_height])
					cylinder($fn = 50, h=chimney_top_height, r1=chimney_top_radius, r2=chimney_top_radius, center=false);  
				}
				cylinder($fn = 50, h=block[Z] - chimney_bridge_gap, r1=chimney_hole_radius, r2=chimney_hole_radius, center=false);  
			}
		}
    }
    
    pedestal_z = abs(overhang_z_top -bridge_z_top + bridge_z);
    translate([block[X]/2 + gap, bridge_y_front, z4]) 
    {
        cube([(overhang-gap)-0.01, bridge_y-0.01, pedestal_z]);
        translate([0,0,pedestal_z])
            cube([abs(x)-block[X]/2-gap, bridge_y, bridge_z]);
    }
    

}

z1 = 0;
translate([0,0,z1+base[Z]/2]) cube(base, true);
z2 = z1 + base[Z];

count = (end_temp - start_temp)/temp_step;

echo("start_temp=", start_temp);
echo("end_temp=", end_temp);
echo("temp_step=", temp_step);
echo("count=", count);

for (i = [0 : abs(count)]) 
{
    z3 = z2 + i*(pedestal[Z] + block[Z]);
    temp = start_temp + i*abs(temp_step);
    echo("-> ", i, ": temp=", temp, "z=", z3);

    translate([0,0,z3]) 
    {
        if(start_temp < end_temp) 
            { Tower(-tower_x_distance/2, overhang_l_x, bridge_l_gap, 0, (start_temp + i*abs(temp_step))); }
        else
            { Tower(-tower_x_distance/2, overhang_l_x, bridge_l_gap, 0, (start_temp + -i*abs(temp_step))); }

        Tower(tower_x_distance/2, overhang_r_x, bridge_r_gap, 1);
    }
}
