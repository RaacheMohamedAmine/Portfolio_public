package uvm_lite_pkg;
  virtual class base_trans;
    pure virtual function base_trans copy();
    pure virtual function bit check();
    pure virtual function void print_row(bit passed);
    virtual function void sample_cov(); endfunction
  endclass

  class scoreboard #(type T = base_trans);
    mailbox #(T) mon2scb;
    int passed_cnt = 0;
    int failed_cnt = 0;

    function new(mailbox #(T) mon2scb);
      this.mon2scb = mon2scb;
    endfunction

    task run();
      T trans;
      forever begin
        mon2scb.get(trans);
        trans.sample_cov();
        if (trans.check()) begin
          passed_cnt++;
          if (passed_cnt <= 10) trans.print_row(1'b1);
        end else begin
          failed_cnt++;
          trans.print_row(1'b0);
          $fatal(1, "Simulation halted due to Scoreboard mismatch.");
        end
      end
    endtask

    function void report(real cov_pct);
      $display("==========================================================================================");
      $display(" VERIFICATION SUMMARY: %0d Passed | %0d Failed | Total Checked: %0d",
               passed_cnt, failed_cnt, passed_cnt + failed_cnt);
      $display(" FUNCTIONAL COVERAGE : %0.2f%%", cov_pct);
      $display("==========================================================================================");
    endfunction
  endclass

  class env #(type T = base_trans, type VIF = int);
    VIF vif;
    int num_tx;
    mailbox #(T) gen2drv;
    mailbox #(T) mon2scb;
    scoreboard #(T) scb;

    function new(VIF vif, int num_tx = 200);
      this.vif     = vif;
      this.num_tx  = num_tx;
      this.gen2drv = new();
      this.mon2scb = new();
      this.scb     = new(mon2scb);
    endfunction

    task run();
      fork
        scb.run();
      join_none

      fork
        begin
          repeat (num_tx) begin
            T t = new();
            assert(t.randomize());
            gen2drv.put(t);
          end
        end
        begin
          T t;
          repeat (num_tx) begin
            gen2drv.get(t);
            vif.drive(t);
          end
        end
        begin
          T t;
          vif.wait_sync();
          repeat (num_tx) begin
            t = new();
            vif.sample(t);
            mon2scb.put(t);
          end
        end
      join
      #10;
    endtask
  endclass
endpackage
