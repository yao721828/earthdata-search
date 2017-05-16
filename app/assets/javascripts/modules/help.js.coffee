
#= require models/data/preferences

data = @edsc.models.data
ui = @edsc.models.ui
ns = @edsc.models.page

@edsc.help = do ($=jQuery, config=@edsc.config, wait = @edsc.util.xhr.wait, page=@edsc.page, PreferencesModel = data.Preferences, urlUtil=@edsc.util.url) ->


  tourOptions =
    tour_end:
      title: 'Tour Ended'
      element: '#main-toolbar h1 a'
      placement: 'bottom'
      content: 'Your tour has ended.  At any point you may restart it by visiting the home page and clicking
                on the "Take a Tour" link.'

  defaultTemplate = "<div class='popover tour'>
                <div class='arrow'></div>
                <h3 class='popover-title'></h3>
                <div class='popover-content'></div>
                <div class='popover-navigation'>
                  <div class='btn-group'>
                    <button class='button-small button-outline' data-role='prev'>« Prev</button>
                    <button class='button-small' data-role='next'>Next <i class='fa fa-arrow-circle-right'></i></button>
                  </div>
                  <button class='button-small button-outline pull-left' data-role='end'>End Tour</button>
                  <label class='pull-left' style='padding-top: 5px;padding-left: 5px;'>
                    <input data-role='toggleHideTour' class='toggleHideTour' type='checkbox' />
                    <small>Do not show again</small>
                  </label>
                </div>
              </div>"

  tour = [{
      title: "Search"
      content: '<p>Use Earthdata Search Client\'s natural language processing-enabled search tool to quickly narrow
                down to relevant collections.  An example search phrase could be "Land Surface Temperature over
                Texas last month".  Results will be displayed in the collection panel below.</p>
                <p>If you would prefer to pick a temporal range from a calendar (<i class="fa fa-clock-o"></i>) or 
                manually set spatial boundaries (<i class="fa fa-fw fa-crop"></i>),
                use the buttons to the right of the search box.</p>
                <p>To start your search session over, click the eraser icon (<i class="fa fa-eraser"></i>) to clear all of your set filters.</p>
                '
      element: '#keywords'
      placement: 'bottom'
      showNext: true
      },{
      title: "Search Results"
      content: '<p>Search results will be shown in the Matching Collections panel below.  Each result will have summary 
                information along with relevant badges to allow you to quickly scan your search results to find the
                right collection for you.  The panel can be resized by clicking and dragging the bar above the "Matching
                Collections" tab.</p>
                <p>To view more information about a collection, click on the <i class="fa fa-info-circle"></i> icon.</p>
                <p>To view granules available for download, click anywhere on a collection.</p>
                <p>Click on the <i class="fa fa-plus"></i> icon to add a collection to a project, which allows you to compare multiple collections.</p>
'
      element: '#collection-results-list'
      placement: 'top'
      showNext: true
      },{
      title: "Facets"
      content: "<p>Refine your search further with available facets, such as:
                <div style='margin-left: 15px;'><ul style='list-style-type: disc;'>
                  <li>Features</li>
                  <li>Keywords</li>
                  <li>Platforms</li>
                  <li>Instruments</li>
                  <li>Organizations</li>
                  <li>Projects</li>
                  <li>Processing Levels</li>
                </ul></div></p>"
      element: "#master-overlay-parent"
      placement: 'right'
      showNext: true
      top: null
    }, {
      title: "Map Tools"
      content: '<p>Use these standard map tools to configure and position the map as well as enable certain spatial search tools.</p>'
      placement: 'left'
      element: '.leaflet-control-zoom-in'
      showNext: true
    }, {
      title: 'Toolbar'
      content: '<p>Use the options available (upon logging in) in the application toolbar to view recent downloads, saved projects, and profile 
      information. You can provide feedback using our feedback module.</p>'
      element: '.user-info'
      placement: 'bottom'
    }]

  defaultHelpOptions =
    placement: 'auto left'
    html: true
    wait: true
    trigger: 'manual'
    template: defaultTemplate
    container: 'body'

  defaultTourOptions =
    reflex: true
    placement: 'left'

  queue = []
  shown = {}
  index = 0
  next = null
  close = null

  tourRunning = false

  doNotShowTourAgain = false

  toggleHideTour = ->
    doNotShowTourAgain = if doNotShowTourAgain then false else true
    $('input:checkbox.toggleHideTour').prop 'checked', doNotShowTourAgain

  hideCurrent = ->
    if queue[index]?
      queue[index].cleanup?(next, close)
      $(queue[index].element).popover('destroy')
      $('.popover-advance').removeClass('popover-advance')

  close = ->
    $('#sitetourModal').modal('hide')
    hideCurrent()
    queue = []
    index = 0
    tourRunning = false

  prev = ->
    if index > 0
      hideCurrent()
      index--
      showCurrent()

  next = ->
    if index < queue.length - 1
      hideCurrent()
      index++
      showCurrent()
    else
      close()

  showCurrentImmediate = ->
    $('.popover-advance').removeClass('popover-advance')

    $el = $(queue[index].element)

    if $el.length > 1
      console.error "Too many elements matched selector #{queue[index].element}.  Showing the first.", $el
      $el = $el.first()

    $el.popover(queue[index])
    $el.attr('data-original-title', '')
    $el.popover('show')
    $el.popover({ html : true })
    
    shown[queue[index].key] = true

    unless queue[index].advanceHook
      $(queue[index].target ? $el).addClass('popover-advance')

    # console.log "Popover: #{queue[index].element} -> #{$el.length}"

    queue[index].advanceHook?(next, close)
    queue[index].closeHook?(close)
    $('input:checkbox.toggleHideTour').prop 'checked', doNotShowTourAgain
    if $el.data('bs.popover')?
      $tip = $el.data('bs.popover').$tip
      $tip.toggleClass('is-popover-single', queue.length == 1)
      if tourRunning
        if index == 0
          $tip.find('[data-role=prev]').hide()
        if index < queue.length - 1
          $tip.find('[data-role=end]').addClass('button-outline')
        else
          $tip.find('[data-role=end]').removeClass('button-outline')

        $tip.find('[data-role=next]').toggle(queue[index].showNext)
      else
        $tip.find('[data-role=end]').text('Close')
        $tip.find('[data-role=prev]').toggle(index != 0)
        $tip.find('[data-role=next]').toggle(index != queue.length - 1)

  showCurrent = ->
    if queue[index].wait
      wait(showCurrentImmediate)
    else if queue[index].waitOnAnimate
      setTimeout((-> wait(showCurrentImmediate)), config.defaultAnimationDurationMs + 200)
    else
      showCurrentImmediate()

  $(document).on 'click', '.popover [data-role=prev]', prev
  $(document).on 'click', '.popover [data-role=next], .popover-advance', next
  $(document).on 'click', '.popover [data-role=toggleHideTour]', toggleHideTour
  $(document).on 'click', '.popover [data-role=end]', ->
    if tourRunning
      preferences = new PreferencesModel()
      preferences.showTour(false)
      preferences.doNotShowTourAgain(doNotShowTourAgain.toString())
      preferences.save()
      close()
      add('tour_end')
    else
      close()

  $(document).on 'click', '.show-tour', (e) ->
    unless window.edscportal
      e.preventDefault()
      startTour()

  $(window).on 'statechange', ->
    $('[id^="show-tour-"]').toggle(urlUtil.cleanPath()?.split('?')[0] in ["/search", "/", ""])
  $(document).on 'ready', ->
    $('[id^="show-tour-"]').toggle(urlUtil.cleanPath()?.split('?')[0] in ["/search", "/", ""])

  add = (key, options={}) ->
    unless tourRunning
      options = $.extend({}, defaultHelpOptions, tourOptions[key], options, key: key)
      for item in queue
        return if item.key == key
      unless options.once && shown[key]
        queue.push(options)
        showCurrent()

  remove = (key) ->
    if queue[0]?.key == key
      next()
    else
      queue = (item for item in queue when item.key != key)

  current = ->
    if tourRunning then nil else queue[index]

  startTour = ->
    close()
    tourRunning = true

    for stop, i in tour
      options = $.extend({}, defaultHelpOptions, stop, key: "tour_#{i}")
      queue.push(options)

    showCurrent()

  exports =
    add: add
    remove: remove
    current: current
    next: next
    prev: prev
    close: close
    startTour: startTour
