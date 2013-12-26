describe 'list', ->
  beforeEach module 'CoffeeModule'

  describe 'addItem', ->
    $scope = ''
    rand = ''
    beforeEach inject ($rootScope, $controller) ->
      rand = Math.floor(Math.random() * (1 << 24)).toString(16)
      $scope = $rootScope.$new()

      $controller 'ListCtrl',
        $scope: $scope

      waitsFor ->
        $scope.loadPouch()

    it 'should exist', ->
      expect($scope.addItem).toBeDefined()
    it 'should add an item', ->
      $scope.addItem rand
      $scope.db.get rand, (err, doc) ->
        expect(err).toBe null
        expect(doc).toBeDefined()

