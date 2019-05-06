require "test_helper"

class IntegrationTest < Minitest::Spec
  class HandleClone < Trailblazer::Activity::Railway
    step :tag_as_cloned

    def tag_as_cloned(_ctx, to_clone:, **)
      to_clone.merge(tag: "cloned")
    end
  end

  class Clone < Trailblazer::Activity::Railway
    step :find
    step Subprocess(HandleClone)
    step :clone!

    def find(ctx, to_clone:, **)
      return false unless to_clone.key? :id

      ctx[:original] = to_clone
    end

    def clone!
      ctx[:clone] = to_clone.dup
    end
  end

  it "clones when passing the correct data" do
    signal, (ctx, *) = Clone.call([{to_clone: {id: 1, name: "MyName"}}], {})

    signal.to_h[:semantic].must_equal :success
    ctx[:clone].must_equal(id: 1, tag: "cloned", name: "MyName")
  end
end
