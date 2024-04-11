//Atmospherics pipes

#define PIPE_SIMPLE_STRAIGHT		0
#define PIPE_SIMPLE_BENT			1
#define PIPE_HE_STRAIGHT			2
#define PIPE_HE_BENT				3
#define PIPE_CONNECTOR				4
#define PIPE_MANIFOLD				5
#define PIPE_JUNCTION				6
#define PIPE_UVENT					7
#define PIPE_MVALVE					8
#define PIPE_PUMP					9
#define PIPE_SCRUBBER				10
#define PIPE_INSULATED_STRAIGHT		11
#define PIPE_INSULATED_BENT			12
#define PIPE_GAS_FILTER				13
#define PIPE_GAS_MIXER				14
#define PIPE_PASSIVE_GATE      		15
#define PIPE_VOLUME_PUMP        	16
#define PIPE_HEAT_EXCHANGE     		17
#define PIPE_TVALVE					18
#define PIPE_MANIFOLD4W				19
#define PIPE_CAP					20
#define PIPE_UNIVERSAL				23
#define PIPE_SUPPLY_STRAIGHT		24
#define PIPE_SUPPLY_BENT			25
#define PIPE_SCRUBBERS_STRAIGHT		26
#define PIPE_SCRUBBERS_BENT			27
#define PIPE_SUPPLY_MANIFOLD		28
#define PIPE_SCRUBBERS_MANIFOLD		29
#define PIPE_SUPPLY_MANIFOLD4W		30
#define PIPE_SCRUBBERS_MANIFOLD4W	31
#define PIPE_SUPPLY_CAP				32
#define PIPE_SCRUBBERS_CAP			33
#define PIPE_INJECTOR    			34
#define PIPE_DVALVE           	 	35
#define PIPE_DP_VENT    			36
#define PIPE_PASV_VENT				37
#define PIPE_DTVALVE				38
#define PIPE_CIRCULATOR				39
#define PIPE_MULTIZ					40
#define PIPE_GAS_SENSOR				98
#define PIPE_METER					99

//Disposals pipes

#define PIPE_DISPOSALS_STRAIGHT			100
#define PIPE_DISPOSALS_BENT				101
#define PIPE_DISPOSALS_JUNCTION_RIGHT	102
#define PIPE_DISPOSALS_JUNCTION_LEFT	103
#define PIPE_DISPOSALS_Y_JUNCTION		104
#define PIPE_DISPOSALS_TRUNK			105
#define PIPE_DISPOSALS_BIN				106
#define PIPE_DISPOSALS_OUTLET			107
#define PIPE_DISPOSALS_CHUTE			108
#define PIPE_DISPOSALS_SORT_RIGHT		109
#define PIPE_DISPOSALS_SORT_LEFT		110
#define PIPE_DISPOSALS_MULTIZ_UP		111
#define PIPE_DISPOSALS_MULTIZ_DOWN		112


//RPD stuff

#define RPD_ATMOS_MODE		1
#define RPD_DISPOSALS_MODE	2
#define RPD_ROTATE_MODE		3
#define RPD_FLIP_MODE		4
#define RPD_DELETE_MODE		5

#define RPD_ATMOS_PIPING		1
#define RPD_SUPPLY_PIPING		2
#define RPD_SCRUBBERS_PIPING	3
#define RPD_DEVICES				4
#define RPD_HEAT_PIPING			5

#define PIPETYPE_ATMOS		1
#define PIPETYPE_DISPOSAL	2

// Connection types

#define CONNECT_TYPE_NORMAL 1
#define CONNECT_TYPE_SUPPLY 2
#define CONNECT_TYPE_SCRUBBER 3
