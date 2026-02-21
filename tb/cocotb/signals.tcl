# signals.tcl
# Automatically load specific signals from the verilator dump.fst in GTKWave

set num_facs [ gtkwave::getNumFacs ]
set facs [list]

lappend facs "detectors_wrapper.clk"
lappend facs "detectors_wrapper.rst"
lappend facs "detectors_wrapper.data_in\[15:0\]"
lappend facs "detectors_wrapper.spike_neo"
lappend facs "detectors_wrapper.spike_ado"
lappend facs "detectors_wrapper.spike_aso"
lappend facs "detectors_wrapper.spike_ed"

set num_added [ gtkwave::addSignalsFromList $facs ]

# Format data_in as Signed and Analog Step
gtkwave::highlightSignalsFromList "detectors_wrapper.data_in\[15:0\]"
gtkwave::/Edit/Data_Format/Signed_Decimal
gtkwave::/Edit/Data_Format/Analog/Step
gtkwave::/Edit/Data_Format/Analog/Resizing/Screen_Data
gtkwave::unhighlightSignalsFromList "detectors_wrapper.data_in\[15:0\]"

gtkwave::setZoomFactor -5
