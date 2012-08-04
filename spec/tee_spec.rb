require 'tee'

require 'stringio'
require 'tempfile'

def temppath
  Tempfile.open(File.basename(__FILE__)) do |file|
    file.path.tap do
      file.close!
    end
  end
end

def create_dummy_file
  temppath.tap do |path|
    File.open(path, 'w') do |file|
      file.write('dummy')
    end
  end
end

describe Tee do
  describe '.open' do
    context 'with a non-existing file path' do
      let(:path) { temppath }

      it 'creates a file at the path' do
        expect { Tee.open(path) {} }.to change { File.exist?(path) }.from(false).to(true)
      end

      after { File.delete(path) }
    end

    context 'with an existing file path' do
      let(:path) { create_dummy_file }

      context 'without mode' do
        it 'overwrites an existing file' do
          Tee.open(path) {}
          File.read(path).should be_empty
        end
      end

      context 'in appending mode' do
        it 'does not overwrite an existing file' do
          Tee.open(path, mode: 'a') {}
          File.read(path).should == 'dummy'
        end
      end

      after { File.delete(path) }
    end
  end

  describe '#write', 'with argument "foo"' do
    context 'when tee is opened with an existing file path' do
      let(:path) { create_dummy_file }

      before :all do
        $stdout = StringIO.new
        Tee.open(path) do |tee|
          tee.write('foo')
        end
      end

      after :all do
        $stdout = STDOUT
        File.delete(path)
      end

      it 'writes `foo` in STDOUT' do
        $stdout.string.should == 'foo'
      end

      it 'overwrites an existing file and writes `foo` in the file' do
        File.read(path).should == 'foo'
      end
    end

    context 'when tee is opened with an existing file path in appending mode' do
      let(:path) { create_dummy_file }

      before :all do
        $stdout = StringIO.new
        Tee.open(path, mode: 'a') do |tee|
          tee.write('foo')
        end
      end

      after :all do
        $stdout = STDOUT
        File.delete(path)
      end

      it 'writes `foo` in STDOUT' do
        $stdout.string.should == 'foo'
      end

      it 'does not overwrite an existing file and appends `foo` to the file' do
        File.read(path).should == 'dummyfoo'
      end
    end

    context 'when tee is opened without arguments' do
      before :all do
        $stdout = StringIO.new
        Tee.open do |tee|
          tee.write('foo')
        end
      end

      after :all do
        $stdout = STDOUT
      end

      it 'writes `foo` in STDOUT' do
        $stdout.string.should == 'foo'
      end
    end

    context 'when tee is opened with two paths' do
      let(:path1) { temppath }
      let(:path2) { temppath }

      before :all do
        $stdout = StringIO.new
        Tee.open(path1, path2) do |tee|
          tee.write('foo')
        end
      end

      after :all do
        $stdout = STDOUT
        File.delete(path1, path2)
      end

      it 'writes `foo` in STDOUT' do
        $stdout.string.should == 'foo'
      end

      it 'writes `foo` in the first file' do
        File.read(path1).should == 'foo'
      end

      it 'writes `foo` in the second file' do
        File.read(path2).should == 'foo'
      end
    end

    context 'when tee is opened with an option `{ stdout: nil }`' do
      let(:path) { temppath }

      before :all do
        $stdout = StringIO.new
        Tee.open(path, stdout: nil) do |tee|
          tee.write('foo')
        end
      end

      after :all do
        $stdout = STDOUT
        File.delete(path)
      end

      it 'writes nothing in STDOUT' do
        $stdout.string.should be_empty
      end

      it 'writes `foo` in the file' do
        File.read(path).should == 'foo'
      end
    end

    context 'when tee is opened with IO instances' do
      let(:path) { temppath }

      before :all do
        $stdout   = StringIO.new
        @stringio = StringIO.new
        open(path, 'w') do |file|
          Tee.open(file, @stringio) do |tee|
            tee.write('foo')
          end
          file.write('bar')
        end
      end

      after :all do
        $stdout = STDOUT
        File.delete(path)
      end

      it 'writes `foo` in STDOUT' do
        $stdout.string.should == 'foo'
      end

      it 'writes `foo` to the File instance' do
        File.read(path).should == 'foobar'
      end

      it 'writes `foo` to the StringIO instance' do
        @stringio.string.should == 'foo'
      end
    end
  end

  describe '#add' do
    let(:path1) { temppath }
    let(:path2) { temppath }

    before :all do
      $stdout = StringIO.new
      Tee.open(path1) do |tee|
        tee.write('foo')
        tee.add(path2)
        tee.write('bar')
      end
    end

    after :all do
      $stdout = STDOUT
      File.delete(path1, path2)
    end

    it 'writes `foobar` in STDOUT' do
      $stdout.string.should == 'foobar'
    end

    it 'writes `foobar` in the first file' do
      File.read(path1).should == 'foobar'
    end

    it 'writes `bar` in the second file' do
      File.read(path2).should == 'bar'
    end
  end
end
