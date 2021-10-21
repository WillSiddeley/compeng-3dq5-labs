`ifndef DEFINE_STATE

// This defines the states

typedef enum logic [4:0] {
	S_WAIT_NEW_PIXEL_ROW,
	S_NEW_PIXEL_ROW_DELAY_1,
	S_NEW_PIXEL_ROW_DELAY_2,
	S_NEW_PIXEL_ROW_DELAY_3,
	S_NEW_PIXEL_ROW_DELAY_4,
	S_NEW_PIXEL_ROW_DELAY_5,
	S_FETCH_PIXEL_DATA_0,
	S_FETCH_PIXEL_DATA_1,
	S_FETCH_PIXEL_DATA_2,
	S_FETCH_PIXEL_DATA_3,
	S_IDLE,
	S_FILL_SRAM_GREEN_EVEN,
	S_FILL_SRAM_BLUE_EVEN,
	S_FILL_SRAM_GREEN_ODD,
	S_FILL_SRAM_BLUE_ODD,
	S_FILL_SRAM_RED_FIRST_COUPLE,
	S_FILL_SRAM_RED_SECOND_COUPLE,
	S_FINISH_FILL_SRAM
} state_type;

parameter NUM_ROW_RECTANGLE = 8,
	  NUM_COL_RECTANGLE = 8,
	  RECT_WIDTH = 40,
	  RECT_HEIGHT = 30,
	  VIEW_AREA_LEFT = 160,
	  VIEW_AREA_RIGHT = 480,
	  VIEW_AREA_TOP = 120,
	  VIEW_AREA_BOTTOM = 360;

// define the base addresses for the green and blue data in the memory
parameter GREEN_EVEN_BASE = 18'd38400,
          BLUE_EVEN_BASE = 18'd57600,
          GREEN_ODD_BASE = 18'd76800,
          BLUE_ODD_BASE = 18'd96000;

`define DEFINE_STATE 1
`endif
