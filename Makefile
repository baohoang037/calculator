ifeq ($(wildcard config.mk),)
$(error "Lỗi: Không tìm thấy file 'config.mk'. Vui lòng tạo file này và định nghĩa các biến cần thiết.")
endif
include config.mk

#====================================================================================
# BIẾN MÔI TRƯỜNG
#====================================================================================
PROJ_ROOT     = $(SRC_DIRS)
RTL_DIR       = $(PROJ_ROOT)/rtl
TB_DIR        = $(PROJ_ROOT)/tb
TC_DIR        = $(PROJ_ROOT)/tc
SIM_DIR       = $(PROJ_ROOT)/sim

TB_MODULE     ?= $(TB_NAME)
RADIX         ?= decimal
COMPILE_FILE  = $(PROJ_ROOT)/compile.f

.PHONY: all all_wave all_cov build build_cov run run_cov wave gen_cov gen_html clean help init

# Khởi tạo cây thư mục và tự phân loại file
init:
	@echo "============================================================"
	@echo " Bắt đầu khởi tạo cây thư mục tại: $(PROJ_ROOT)"
	@echo "============================================================"
	@mkdir -p $(RTL_DIR) $(TB_DIR) $(TC_DIR) $(SIM_DIR)
	@echo " Đã tạo các thư mục: rtl, tb, tc, sim."
	@bash -c ' \
	    for f in $(wildcard $(PROJ_ROOT)/*.v $(PROJ_ROOT)/*.sv); do \
	        filename=$$(basename $$f); \
	        if [[ "$$filename" == tb_* ]]; then \
	            mv $$f $(TB_DIR)/; \
	            echo "   -> Đã chuyển $$filename (Testbench) tới $(TB_DIR)"; \
	        elif [[ "$$filename" == tc_* ]]; then \
	            mv $$f $(TC_DIR)/; \
	            echo "   -> Đã chuyển $$filename (Testcase) tới $(TC_DIR)"; \
	        else \
	            mv $$f $(RTL_DIR)/; \
	            echo "   -> Đã chuyển $$filename (RTL) tới $(RTL_DIR)"; \
	        fi \
	    done \
	'
	@echo " Đang tạo file compile.f ..."
	@( \
	    echo "// --- RTL Files ---"; \
	    find $(RTL_DIR) -type f \( -name "*.v" -o -name "*.sv" \) 2>/dev/null; \
	    echo "// --- Testbench Files ---"; \
	    find $(TB_DIR) -type f \( -name "*.v" -o -name "*.sv" \) 2>/dev/null; \
	) > $(COMPILE_FILE)
	@echo " Đã tạo file $(COMPILE_FILE)"
	@echo "============================================================"

all: build run
all_wave: build run wave
all_cov: build_cov run_cov

build:
	@mkdir -p $(SIM_DIR)/log
	cd $(SIM_DIR) && vlib work
	cd $(SIM_DIR) && vmap work work
	cd $(SIM_DIR) && vlog -sv -f $(COMPILE_FILE) +incdir+$(RTL_DIR) +incdir+$(TC_DIR) | tee log/compile.log

build_cov:
	@mkdir -p $(SIM_DIR)/log
	cd $(SIM_DIR) && vlib work
	cd $(SIM_DIR) && vmap work work
	cd $(SIM_DIR) && vlog -sv +cover=bcesft -f $(COMPILE_FILE) +incdir+$(RTL_DIR) +incdir+$(TC_DIR) | tee log/compile.log

run:
	cd $(SIM_DIR) && vsim -debugDB -l sim.log -voptargs="+acc" -assertdebug -c $(TB_MODULE) -do "log -r /*; run -all; quit"

run_cov:
	cd $(SIM_DIR) && vsim -coverage -l sim.log -c $(TB_MODULE) -voptargs="+cover=bcesft" -assertdebug -do "coverage save -onexit coverage.ucdb; log -r /*; run -all; quit"

wave:
	cd $(SIM_DIR) && vsim -i -view vsim.wlf -do "add wave -r /*; radix -$(RADIX)" &

gen_cov:
	@mkdir -p $(SIM_DIR)/coverage
	cd $(SIM_DIR) && vcover merge coverage/IP.ucdb *.ucdb
	cd $(SIM_DIR) && vcover report coverage/IP.ucdb -output coverage/summary_report.txt
	cd $(SIM_DIR) && vcover report -details -code bcesft -annotate -All -codeAll coverage/IP.ucdb -output coverage/detail_report.txt
	@echo "--- Báo cáo Text đã tạo: $(SIM_DIR)/coverage/detail_report.txt ---"

view_cov:
	cd $(SIM_DIR) && vsim -gui -viewcov coverage/IP.ucdb &

gen_html:
	@mkdir -p $(SIM_DIR)/coverage
	cd $(SIM_DIR) && vcover merge coverage/IP.ucdb *.ucdb
	cd $(SIM_DIR) && vcover report -details -code bcesft -annotate -testhitdataAll -html coverage/IP.ucdb -output coverage/covhtmlreport
	@echo "--- Báo cáo HTML đã tạo: $(SIM_DIR)/coverage/covhtmlreport ---"

clean:
	rm -rf $(SIM_DIR)/*
	@echo "--- Đã dọn dẹp sạch sẽ sim ---"

# Mở báo cáo HTML trực tiếp bằng Google Chrome
view_html:
	google-chrome $(SIM_DIR)/coverage/covhtmlreport/index.html &
