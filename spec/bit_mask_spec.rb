require 'spec_helper'
require 'ffi/bit_masks/bit_mask'

describe FFI::BitMasks::BitMask do
  let(:flags) { {:foo => 0x1, :bar => 0x2, :baz => 0x4} }

  subject { described_class.new(flags) }

  describe "#initialize" do
    subject { described_class.new(flags) }

    it "should initialize the flags" do
      expect(subject.flags).to eq(flags)
    end

    it "should invert the flags into bitmasks" do
      expect(subject.bitmasks).to eq(flags.invert)
    end

    it "should default type to uint" do
      expect(subject.native_type).to eq(FFI::Type::UINT)
    end

    context "when given a custom type" do
      subject { described_class.new(flags,:ushort) }

      it "should set native type" do
        expect(subject.native_type).to eq(FFI::Type::USHORT)
      end
    end
  end

  describe "#symbols" do
    it "should return the names of the flags" do
      expect(subject.symbols).to eq(flags.keys)
    end
  end

  describe "#symbol_map" do
    it "should return the flags" do
      expect(subject.symbol_map).to eq(flags)
    end
  end

  describe "#to_h" do
    it "should return the flags" do
      expect(subject.to_h).to eq(flags)
    end
  end

  describe "#to_hash" do
    it "should return the flags" do
      expect(subject.to_hash).to eq(flags)
    end
  end

  describe "#[]" do
    context "when given a Symbol" do
      it "should lookup the bitmask" do
        expect(subject[:bar]).to eq(flags[:bar])
      end
    end

    context "when given an Integer" do
      it "should lookup the flag" do
        expect(subject[flags[:bar]]).to eq(:bar)
      end
    end

    context "otherwise" do
      it "should return nil" do
        expect(subject[Object.new]).to be_nil
      end
    end
  end

  describe "#to_native" do
    context "when given a Hash" do
      let(:hash) { {:foo => true, :bar => true, :baz => false} }

      it "should bitwise or together the flag masks" do
        expect(subject.to_native(hash)).to eq(flags[:foo] | flags[:bar])
      end

      context "when one of the keys does not correspond to a flag" do
        let(:hash) { {:foo => true, :bug => true, :baz => true} }

        it "should ignore the key" do
          expect(subject.to_native(hash)).to eq(flags[:foo] | flags[:baz])
        end
      end
    end

    context "when an Object that respnds to #to_int" do
      let(:int) { 0x3 }

      it "should call #to_int" do
        expect(subject.to_native(int)).to eq(0x3)
      end

      context "when given a bitmask that contains unknown masks" do
        let(:int) { flags[:foo] | flags[:bar] | 0x8 | 0x10 }

        it "should filter out the unknown masks" do
          expect(subject.to_native(int)).to eq(
            flags[:foo] | flags[:bar]
          )
        end
      end
    end

    context "when given an Object that does not respond to #to_int" do
      it "should raise an ArgumentError" do
        expect {
          subject.to_native(Object.new)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#from_native" do
    let(:value) { flags[:foo] | flags[:baz] }

    it "should set the flags from the value" do
      expect(subject.from_native(value)).to eq({
        :foo => true,
        :bar => false,
        :baz => true
      })
    end

    context "when one flag is a combination of other flags" do
      let(:flags) { {:foo => 0x1, :bar => 0x2, :baz => 0x3} }
      let(:value) { flags[:foo] | flags[:bar]      }

      it "should set all flags whose bitmasks are present" do
        expect(subject.from_native(value)).to eq({
          :foo => true,
          :bar => true,
          :baz => true
        })
      end
    end

    context "when given a value that contains unknown masks" do
      let(:value) { flags[:foo] | flags[:baz] | 0x8 | 0x10 }

      it "should ignore the unknown flags" do
        expect(subject.from_native(value)).to eq({
          :foo => true,
          :bar => false,
          :baz => true
        })
      end
    end
  end
end
