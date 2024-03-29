//----------------------------------------------------------------------
//   Copyright 2007-2011 Mentor Graphics Corporation
//   Copyright 2007-2010 Cadence Design Systems, Inc. 
//   Copyright 2010 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//----------------------------------------------------------------------


//------------------------------------------------------------------------------
//
// CLASS: uvm_sequence #(REQ,RSP)
//
// The uvm_sequence class provides the interfaces necessary in order to create
// streams of sequence items and/or other sequences.
//
//------------------------------------------------------------------------------

virtual class uvm_sequence #(type REQ = uvm_sequence_item,
                             type RSP = REQ) extends uvm_sequence_base;

  typedef uvm_sequencer_param_base #(REQ, RSP) sequencer_t;

  sequencer_t        param_sequencer;
  REQ                req;
  RSP                rsp;

  // Function: new
  //
  // Creates and initializes a new sequence object.

  function new (string name = "uvm_sequence");
    super.new(name);
  endfunction

  // Function: send_request
  //
  // This method will send the request item to the sequencer, which will forward
  // it to the driver.  If the rerandomize bit is set, the item will be
  // randomized before being sent to the driver. The send_request function may
  // only be called after <uvm_sequence_base::wait_for_grant> returns.

  function void send_request(uvm_sequence_item request, bit rerandomize = 0);
    REQ m_request;
    
    if (m_sequencer == null) begin
      uvm_report_fatal("SSENDREQ", "Null m_sequencer reference", UVM_NONE);
    end
    if (!$cast(m_request, request)) begin
      uvm_report_fatal("SSENDREQ", "Failure to cast uvm_sequence_item to request", UVM_NONE);
    end
    m_sequencer.send_request(this, m_request, rerandomize);
  endfunction


  // Function: get_current_item
  //
  // Returns the request item currently being executed by the sequencer. If the
  // sequencer is not currently executing an item, this method will return null.
  //
  // The sequencer is executing an item from the time that get_next_item or peek
  // is called until the time that get or item_done is called.
  //
  // Note that a driver that only calls get will never show a current item,
  // since the item is completed at the same time as it is requested.

  function REQ get_current_item();
    if (!$cast(param_sequencer, m_sequencer))
      uvm_report_fatal("SGTCURR", "Failure to cast m_sequencer to the parameterized sequencer", UVM_NONE);
    return (param_sequencer.get_current_item());
  endfunction


  // Task: get_response
  //
  // By default, sequences must retrieve responses by calling get_response.
  // If no transaction_id is specified, this task will return the next response
  // sent to this sequence.  If no response is available in the response queue,
  // the method will block until a response is recieved.
  //
  // If a transaction_id is parameter is specified, the task will block until
  // a response with that transaction_id is received in the response queue.
  //
  // The default size of the response queue is 8.  The get_response method must
  // be called soon enough to avoid an overflow of the response queue to prevent
  // responses from being dropped.
  //
  // If a response is dropped in the response queue, an error will be reported
  // unless the error reporting is disabled via
  // set_response_queue_error_report_disabled.

  virtual task get_response(output RSP response, input int transaction_id = -1);
    uvm_sequence_item rsp;
    get_base_response( rsp, transaction_id);
    $cast(response,rsp);
  endtask



  // Function- put_response
  //
  // Internal method.

  virtual function void put_response(uvm_sequence_item response_item);
    RSP response;
    if (!$cast(response, response_item)) begin
      uvm_report_fatal("PUTRSP", "Failure to cast response in put_response", UVM_NONE);
    end
    put_base_response(response_item);
  endfunction


  virtual function void put_base_response(input uvm_sequence_item response);
    if ((response_queue_depth == -1) ||
        (response_queue.size() < response_queue_depth)) begin
      response_queue.push_back(response);
      return;
    end
    if (response_queue_error_report_disabled == 0) begin
      uvm_report_error(get_full_name(), "Response queue overflow, response was dropped", UVM_NONE);
    end
  endfunction


  function void do_print (uvm_printer printer);
    super.do_print(printer);
    printer.print_object("req", req);
    printer.print_object("rsp", rsp);
  endfunction

  
  

  // Function- create_request
  //
  // Returns an instance of the ~REQ~ type in a <uvm_sequence_item> base handle.
  // Used for type-compatibility checking. Unrelated (inheritance-wise) sequence
  // A #(R1,S1) can run on sequencer #(R,S) as long as R1 and S1 are by themselves
  // type-compatible with R and S, respectively.
  virtual function uvm_sequence_item create_request ();
    REQ req;
    req = new();
    return req;
  endfunction

  // Function- create_response
  //
  // Returns an instance of the ~RSP~ type in a <uvm_sequence_item> base handle.
  // Used for type-compatibility checking. Unrelated (inheritance-wise) sequence
  // A #(R1,S1) can run on sequencer #(R,S) as long as R1 and S1 are by themselves
  // type-compatible with R and S, respectively.
  virtual function uvm_sequence_item create_response ();
    RSP rsp;
    rsp = new();
    return rsp;
  endfunction




endclass
