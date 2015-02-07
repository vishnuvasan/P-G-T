  % include templates/includes/error.tpl


  <h1> </h1>

  <form method='POST'>

    <div class="control-group">
      <label for="" class="control-label"> Enable OMSSA </label>
      <div class="controls">
        <div class="slide-checkbox">  
          <input type="checkbox" value="on" id="checkbox1" name="omssa_enabled" class="on-off" {{config[kind]['enabled']}}/>
          <label for="checkbox1"></label>
        </div>
      </div>
    </div>

    % include templates/includes/input.tpl path=True, label="Path", name="omssa_path", value=config[kind]['path'], help='Filesystem path for OMSSA'

    % include templates/includes/input.tpl path=True, label="FormatDB", name="omssa_formatdb", value=config[kind]['formatdb'], help='Path to FormatDB'

    <div class="control-group">
      <label class="control-label" for="text-input1"> Other Options </label>
      <div class="controls">
        <input type="text" class="input-xxlarge path-typeahead" name='omssa_options' value='{{ config[ kind ][ 'options' ] }}'  /> 
      </div>
    </div>

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True

