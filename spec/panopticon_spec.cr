require "./spec_helper"

describe Panopticon do
  describe ".extract" do
    it "detects correlation IDs in request headers" do
      id = Panopticon.generate_id
      req = HTTP::Request.new "GET", "/"
      req.headers[Panopticon::HTTPHeader] = id
      Panopticon.extract(req).should eq(id)
    end
  end

  describe ".id, id=" do
    it "inserts and extracts from a fiber context" do
      id = Panopticon.generate_id
      in_fiber do
        Panopticon.id = id
        Panopticon.id.should eq(id)
      end
    end

    it "persists an ID once created" do
      in_fiber do
        id1 = Panopticon.id
        id2 = Panopticon.id
        id1.should eq(id2)
      end
    end
  end

  describe "id?" do
    it "returns `nil` if an ID does not exist" do
      in_fiber do
        Panopticon.id?.should be_nil
      end
    end

    it "returns the ID" do
      in_fiber do
        id = Panopticon.id
        Panopticon.id?.should eq(id)
      end
    end
  end

  describe ".inject" do
    it "does not pollute sibling fibers" do
      id = Panopticon.generate_id
      in_fiber { Panopticon.inject id, Fiber.current }
      in_fiber { Panopticon.extract(Fiber.current).should be_nil }
    end

    it "does not pollute parent fibers" do
      id = Panopticon.generate_id
      in_fiber do
        in_fiber { Panopticon.inject id, Fiber.current }
        Panopticon.extract(Fiber.current).should be_nil
      end
    end

    it "propogates to child fibers" do
      id = Panopticon.generate_id
      in_fiber do
        Panopticon.inject id, Fiber.current
        in_fiber { Panopticon.id.should eq(id) }
      end
    end

    it "persists the ID when when logging context is cleared" do
      id = Panopticon.generate_id
      in_fiber do
        Panopticon.inject id, Fiber.current
        ::Log.context.clear
        Panopticon.id.should eq(id)
      end
    end
  end

  describe ".propagate" do
    it "copies an ID between fibers" do
      id = Panopticon.generate_id
      ch = Channel(Nil).new
      fib1 = spawn { Panopticon.id = id; ch.receive }
      fib2 = spawn { ch.receive }
      Fiber.yield
      Panopticon.extract(fib1).should eq(id)
      Panopticon.extract(fib2).should be_nil
      Panopticon.propagate(fib2, fib1)
      Panopticon.extract(fib2).should eq(id)
      2.times { ch.send nil }
    end

    it "copies an ID from the current fiber to a HTTP request" do
      in_fiber do
        id = Panopticon.id
        req = HTTP::Request.new "GET", "/"
        Panopticon.extract(req).should be_nil
        Panopticon.propagate(req)
        Panopticon.extract(req).should eq(id)
      end
    end
  end

  describe ".attach" do
    # Note: .attach is applied within core_ext/http/server/context

    it "applies a recieved ID to the current context" do
      id = Panopticon.generate_id
      service_id = nil

      service = with_server do |context|
        service_id = Panopticon.id
      end

      headers = HTTP::Headers.new
      headers[Panopticon::HTTPHeader] = id
      HTTP::Client.get service, headers

      service_id.should eq(id)
    end

    it "propagates across service boundaries" do
      id = Panopticon.generate_id
      service_a_id = nil
      service_b_id = nil

      service_a = with_server do |context|
        service_a_id = Panopticon.id
      end

      service_b = with_server do |context|
        service_b_id = Panopticon.id
        HTTP::Client.get service_a
      end

      headers = HTTP::Headers.new
      headers[Panopticon::HTTPHeader] = id
      HTTP::Client.get service_b, headers

      service_a_id.should eq(id)
      service_b_id.should eq(id)
    end

    it "generates a new ID on entry to the first service" do
      service_a_id = nil
      service_b_id = nil

      service_a = with_server do |context|
        service_a_id = Panopticon.id
      end

      service_b = with_server do |context|
        service_b_id = Panopticon.id
        HTTP::Client.get service_a
      end

      HTTP::Client.get service_b

      service_a_id.should_not be_nil
      service_a_id.should eq(service_b_id)
    end

    it "does not correlate unrelated transactions" do
      service_a_id = nil
      service_b_id = nil

      service_a = with_server do |context|
        service_a_id = Panopticon.id
      end

      service_b = with_server do |context|
        service_b_id = Panopticon.id
      end

      HTTP::Client.get service_a
      HTTP::Client.get service_b

      service_a_id.should_not be_nil
      service_b_id.should_not be_nil
      service_a_id.should_not eq(service_b_id)
    end
  end
end
