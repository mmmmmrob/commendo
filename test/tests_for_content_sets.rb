module TestsForContentSets

  def contains_resource(resource, similarities)
    !similarities.select { |sim| sim[:resource] == "#{resource}" }.empty?
  end

  def similar_to(cs, resource, similar)
    contains_resource(similar, cs.similar_to(resource))
  end

  def test_recommends_for_many_applies_filters
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity
    actual = @cs.filtered_similar_to([12, 6, 9], include: ['mod4'], exclude: ['mod3', 'mod5'])
    refute contains_resource('6', actual)
    refute contains_resource('18', actual)
    assert contains_resource('4', actual)
    refute contains_resource('3', actual)
    refute contains_resource('9', actual)
    assert contains_resource('8', actual)
    refute contains_resource('21', actual)
    assert contains_resource('16', actual)
    refute contains_resource('15', actual)
    refute contains_resource('20', actual)
  end

  def test_recommends_for_many
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity
    expected = [
        {resource: '18', similarity: 1.834},
        {resource: '3', similarity: 1.734},
        {resource: '6', similarity: 1.167},
        {resource: '21', similarity: 1.086},
        {resource: '15', similarity: 1.086},
        {resource: '12', similarity: 1.0},
        {resource: '9', similarity: 0.833},
        {resource: '4', similarity: 0.4},
        {resource: '8', similarity: 0.333},
        {resource: '16', similarity: 0.286},
        {resource: '20', similarity: 0.25}
    ]
    actual = @cs.similar_to([12, 6, 9])
    assert_equal expected, actual
    #, include: ['mod4'], exclude: ['mod3', 'mod5']
  end

  def test_filters_includes_and_exclude_by_tag_collection
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    #Build some test data
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity

    actual = @cs.filtered_similar_to(12, include: ['mod4'], exclude: ['mod3', 'mod5'])
    assert_equal 3, actual.length

    refute contains_resource('6', actual)
    refute contains_resource('18', actual)
    assert contains_resource('4', actual)
    refute contains_resource('3', actual)
    refute contains_resource('9', actual)
    assert contains_resource('8', actual)
    refute contains_resource('21', actual)
    assert contains_resource('16', actual)
    refute contains_resource('15', actual)
    refute contains_resource('20', actual)
  end

  def test_filters_exclude_by_tag_collection
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity

    actual = @cs.filtered_similar_to(10, exclude: ['mod3'])
    assert_equal 2, actual.length
    assert contains_resource('5', actual)
    assert contains_resource('20', actual)
    refute contains_resource('15', actual)
  end

  def test_filters_include_by_tag_collection_and_limit
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity

    actual = @cs.filtered_similar_to(10, include: ['mod5'], limit: 2)
    assert_equal 2, actual.length
    assert contains_resource('5', actual)
    #assert contains_resource('15', actual)
    assert contains_resource('20', actual)

  end

  def test_filters_include_by_tag_collection
    ts = create_tag_set("#{@key_base}:tags")
    @cs = create_content_set(@key_base, ts)
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
        ts.add(res, 'mod3') if res.modulo(3).zero?
        ts.add(res, 'mod4') if res.modulo(4).zero?
        ts.add(res, 'mod5') if res.modulo(5).zero?
      end
    end
    @cs.calculate_similarity

    actual = @cs.filtered_similar_to(10, include: ['mod5'])
    assert_equal 3, actual.length
    assert contains_resource('5', actual)
    assert contains_resource('15', actual)
    assert contains_resource('20', actual)

  end

  def test_remove_and_calculate
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
      end
    end
    @cs.calculate_similarity
    assert similar_to(@cs, 18, 12)
    @cs.remove_from_groups_and_calculate(18, 6, 3)
    refute similar_to(@cs, 18, 12)
  end

  def test_accepts_incremental_updates
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
      end
    end
    @cs.calculate_similarity
    assert similar_to(@cs, 18, 12)
    refute similar_to(@cs, 10, 12)

    @cs.add_and_calculate(12, 'foo', true)
    @cs.add_and_calculate(10, 'foo', true)
    assert similar_to(@cs, 10, 12)
  end

  def test_remove_causes_similarity_to_change_when_recalculated
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
      end
    end
    @cs.calculate_similarity
    assert similar_to(@cs, 18, 12)
    @cs.remove_from_groups(18, 6, 3)
    @cs.calculate_similarity
    refute similar_to(@cs, 18, 12)
  end

  def test_remove_from_groups
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add(res, group) if res % group == 0
      end
    end
    resource = 20
    assert_equal ['4', '5', '10', '20'].sort!, @cs.groups(resource).sort!
    @cs.remove_from_groups(resource, 10)
    assert_equal ['4', '5', '20'].sort!, @cs.groups(resource).sort!
    @cs.remove_from_groups(resource, 4)
    assert_equal ['5', '20'].sort!, @cs.groups(resource).sort!
  end

  def test_deletes_resource_from_everywhere
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add_by_group(group, res) if res % group == 0
      end
    end
    @cs.calculate_similarity
    assert similar_to(@cs, 18, 12)

    @cs.delete(12)
    assert_equal [], @cs.similar_to(12)
    refute similar_to(@cs, 18, 12)

    @cs.calculate_similarity
    assert_equal [], @cs.similar_to(12)
    refute similar_to(@cs, 18, 12)
  end

  def test_calculate_copes_with_missing_resource
    @cs.calculate_similarity_for_resource('999999999999', 0.1)
  end

  def test_calculates_with_threshold
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add_by_group(group, res) if res % group == 0
      end
    end
    @cs.calculate_similarity(0.4)
    expected = [
        {resource: '9', similarity: 0.667},
        {resource: '6', similarity: 0.667},
        {resource: '12', similarity: 0.5}
    ]
    assert_equal expected, @cs.similar_to(18)
  end

  def test_calculates_similarity_scores
    (3..23).each do |group|
      (3..23).each do |res|
        @cs.add_by_group(group, res) if res % group == 0
      end
    end
    @cs.calculate_similarity
    expected = [
        {resource: '9', similarity: 0.667},
        {resource: '6', similarity: 0.667},
        {resource: '12', similarity: 0.5},
        {resource: '3', similarity: 0.4},
        {resource: '21', similarity: 0.286},
        {resource: '15', similarity: 0.286}
    ]
    assert_equal expected, @cs.similar_to(18)
  end

  def test_recommendations_are_isolated_by_key_base
    cs1 = create_content_set('ContentSetOne')
    cs2 = create_content_set('ContentSetTwo')
    cs1.add('1', 'a group')
    cs2.add('2', 'a group')
    cs1.add('3', 'a group')
    cs2.add('4', 'a group')
    cs1.add('5', 'a group')
    cs2.add('6', 'a group')
    cs1.calculate_similarity
    cs2.calculate_similarity
    assert_equal [{resource: '5', similarity: 1.0}, {resource: '3', similarity: 1.0}], cs1.similar_to('1')
    assert_equal [{resource: '6', similarity: 1.0}, {resource: '4', similarity: 1.0}], cs2.similar_to('2')
  end

  def test_recommends_when_added_by_group_with_scores
    @cs.add_by_group('group-1', ['resource-1', 2], ['resource-2', 3], ['resource-3', 7])
    @cs.add_by_group('group-2', ['resource-1', 2], ['resource-3', 3], ['resource-4', 5])
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-3', similarity: 1.0},
        {resource: 'resource-4', similarity: 0.778},
        {resource: 'resource-2', similarity: 0.714}
    ]
    assert_equal expected, @cs.similar_to('resource-1')
  end

  def test_recommends_when_added_by_group
    @cs.add_by_group('group-1', 'resource-1', 'resource-2', 'resource-3')
    @cs.add_by_group('group-2', 'resource-1', 'resource-3', 'resource-4')
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-3', similarity: 1.0},
        {resource: 'resource-4', similarity: 0.667},
        {resource: 'resource-2', similarity: 0.667}
    ]
    assert_equal expected, @cs.similar_to('resource-1')
  end

  def test_recommends_when_extra_scores_added
    test_recommends_when_added_with_scores #sets up the content set
    @cs.add('resource-3', ['group-1', 1], ['group-3', 2])
    @cs.add('resource-4', ['group-2', 1])
    @cs.add_by_group('group-1', ['newource-9', 100], 'resource-2', 'resource-3')
    @cs.add_by_group('group-2', 'resource-1', 'resource-3', 'resource-4')
    @cs.calculate_similarity
    expected = [
        {resource: 'newource-9', similarity: 1.0},
        {resource: 'resource-1', similarity: 0.769},
        {resource: 'resource-3', similarity: 0.706}
    ]
    actual = @cs.similar_to('resource-2')
    assert_equal expected, actual
  end

  def test_recommends_with_large_number_of_groups
    (0..3000).each do |i|
      @cs.add('resource-1', ["group-#{i}", i/100.0], ["group-#{i+1}", i/20.0])
      @cs.add('resource-9', ["group-#{i}", i/100.0], ["group-#{i+1}", i/20.0])
    end
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-9', similarity: 1.0}
    ]
    assert_equal expected, @cs.similar_to('resource-1')
  end

  def test_recommends_when_added_with_scores
    @cs.add('resource-1', ['group-1', 2], ['group-2', 2])
    @cs.add('resource-2', ['group-1', 7])
    @cs.add('resource-3', ['group-1', 2], ['group-2', 2])
    @cs.add('resource-4', ['group-2', 3])
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-3', similarity: 1.0},
        {resource: 'resource-2', similarity: 0.818},
        {resource: 'resource-4', similarity: 0.714}
    ]
    actual = @cs.similar_to('resource-1')
    assert_equal expected, actual
  end

  def test_recommends_limited_by_number
    @cs.add('resource-1', 'group-1', 'group-2')
    @cs.add('resource-2', 'group-1')
    @cs.add('resource-3', 'group-1', 'group-2')
    @cs.add('resource-4', 'group-2')
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-3', similarity: 1.0},
        {resource: 'resource-4', similarity: 0.667},
        {resource: 'resource-2', similarity: 0.667}
    ]
    assert_equal expected[0..0], @cs.similar_to('resource-1', 1)
    assert_equal expected[0..1], @cs.similar_to('resource-1', 2)
    assert_equal expected, @cs.similar_to('resource-1', 3)
    assert_equal expected, @cs.similar_to('resource-1', 99)
  end

  def test_recommends_when_added
    @cs.add('resource-1', 'group-1', 'group-2')
    @cs.add('resource-2', 'group-1')
    @cs.add('resource-3', 'group-1', 'group-2')
    @cs.add('resource-4', 'group-2')
    @cs.calculate_similarity
    expected = [
        {resource: 'resource-3', similarity: 1.0},
        {resource: 'resource-4', similarity: 0.667},
        {resource: 'resource-2', similarity: 0.667}
    ]
    assert_equal expected, @cs.similar_to('resource-1')
  end

end