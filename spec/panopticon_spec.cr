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

  describe ".replicate" do
    it "copies an ID between fibers" do
      id = Panopticon.generate_id
      ch = Channel(Nil).new
      fib1 = spawn { Panopticon.id = id; ch.receive }
      fib2 = spawn { ch.receive }
      Fiber.yield
      Panopticon.extract(fib1).should eq(id)
      Panopticon.extract(fib2).should be_nil
      Panopticon.replicate(fib2, fib1)
      Panopticon.extract(fib2).should eq(id)
      2.times { ch.send nil }
    end
  end
end
