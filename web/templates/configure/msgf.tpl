  <h1> </h1>

  % include templates/includes/error.tpl

  <form method='POST'>

    <div class="control-group">
      <label for="" class="control-label"> Enable MSGF+</label>
      <div class="controls">
        <div class="slide-checkbox">  
          <input type="checkbox" value="on" id="checkbox1" name="msgf_enabled" class="on-off" {{config[kind]['enabled']}}/>
          <label for="checkbox1"></label>
        </div>
      </div>
    </div>

    % include templates/includes/input.tpl path=True, label="Path", name="msgf_path", value=config[kind]['path'], help='Filesystem path for MSGF+'

    <div class="control-group">
      <label class="control-label" for="text-input1"> Other Options </label>
      <div class="controls">
        <input type="text" class="input-xxlarge path-typeahead" name='msgf_options' value='{{ config[ kind ][ 'options' ] }}'  /> 
      </div>
    </div>

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True

