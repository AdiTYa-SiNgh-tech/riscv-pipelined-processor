# 1. First, create a new project called "proj_no_buffer" in the NO_buffer folder
# (Change the part number if you are using a different FPGA, this uses a standard Basys3 part)
create_project proj_no_buffer "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/proj_no_buffer" -part xc7z010clg400-1 -force

# 2. Add all Verilog design files from the NO_buffer directory
add_files "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/alu.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/alu_control.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/branch_unit.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/cache_controller.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/control_unit.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/ex_mem_reg.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/forwarding_unit.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/hazard_detection_unit.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/id_ex_reg.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/if_id_reg.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/imm_gen.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/instruction_memory.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/l1_cache.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/main_memory.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/mem_wb_reg.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/pipelined_riscv.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/program_counter.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/register_file.v" \
          "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/write_buffer.v"

# 3. Set the top-level design module
set_property top pipelined_riscv [current_fileset]

# 4. Add the specific testbench and set it for Simulation Only
add_files -fileset sim_1 "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/tb_write_buffer.v"
set_property USED_IN_SYNTHESIS 0 [get_files "C:/Users/shive/OneDrive/Attachments/Desktop/CO_PROJECT_NEW/NO_buffer/tb_write_buffer.v"]

# 5. Set the top-level simulation module
set_property top tb_write_buffer [get_filesets sim_1]

# 6. Update compile order (tells Vivado to figure out file dependencies)
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 7. Set simulation runtime and launch
set_property -name {xsim.simulate.runtime} -value {300us} -objects [get_filesets sim_1]
launch_simulation
