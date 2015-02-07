
<h1> Genome Run </h1>

  % if len( errors ) > 0:
    % for error in errors:
      <div class='alert'>
      % if config_error:
        <div>
          Please configure {{ error }} before creating workflow
          <a class="btn btn-primary" href="/configure/omssa"> Click here to configure </a>
        </div>
      % else:
        {{ error }}
      % end
      </div>
    % end
  % end 

    <form method='post' class='form-horizontal' enctype='multipart/form-data'>
      <fieldset title='Input File'>
        <legend> Setup Input </legend>
        <div class='control-group'>
          <label class='control-label'> Path</label>
          <input type='text' class='input-xxlarge path-typeahead' placeholder="Input File" name='input' autocomplete='off'/>
        </div>
        <h3 class=''> OR </h3>
        <div class='control-group'>
          <label class='control-label'> Upload </label>
          <input type='file' name='input_file' />
        </div>
      </fieldset>

      % if database_config:
        <fieldset title='Database'>
          % keys = database_config.keys()
          % keys.sort()

          % labels = map(  lambda x: x, keys ) 
          % include templates/includes/radio.tpl name="database", labels=labels, values=labels, title="Database"
        </fieldset>
      % end

      % include templates/includes/submit.tpl label='Run'

    </form>

%rebase templates/layout kind='genome_run', is_workflow=True 
