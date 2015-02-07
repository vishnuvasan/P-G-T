
<div class='hero-unit'>

  % if errors and len( errors ) > 0:
    % for error in errors:
      <div class='alert'>
        {{ error }}
      </div>
    % end
  % end


  <form id='step' class='form-horizontal' method='POST'>

    % for _type in types:

      <fieldset title="{{ _type.upper() }}">
        <legend> Setup {{ _type.upper() }} </legend>

        <div class='control-group'>
          <label class='control-label'> Path </label>

          % if config[ _type ]['path']:
            <input type='text' placeholder="{{ _type.upper() }} Path" name='{{ _type }}_path' value='{{ config[ _type ]['path'] }}' />
          % else:
            <input type='text' placeholder="{{ _type.upper() }} Path" name='{{ _type }}_path' />
          % end
        </div>

        <div class='control-group'>

          <label class='control-label'> Options </label>

          % if config[ _type ]['options']:
            <input type='text' value="{{ config[ _type ][ 'options' ] }}" name='{{ _type }}_options'/>
          % else:
              % if _type == "omssa":
                 % opt = "-e 10 -to 0.8 -te 2 -tom 0 -tem 0 -w"
              % elif _type == "msgf":
                 % opt = "-t 20ppm -ti -1,2 -ntt 2 -tda 1 "
              % else:
                 % opt = ""
              % end
            <input type='text' value="{{ opt }}" name='{{ _type }}_options'/>
          % end

        </div>
      </fieldset>

    % end



    <fieldset title="FDR">
      <legend> Setup FDR Parameters </legend>

      <div class='control-group'>
        <label class='control-label'> Use Concatenated Decoy?</label>
        <input type='radio' name='use_concatenated_decoy' value='1'> Yes 
        <input type='radio' name='use_concatenated_decoy' value='0'> No 
      </div>

      <div class='control-group'>
        <label class='control-label'> Use FDR Score and not normal FDR? </label>
        <input type='radio' name='use_fdr_score' value='1'> Yes 
        <input type='radio' name='use_fdr_score' value='0'> No 
      </div>

      <div class='control-group'>
        <label class='control-label'> FDR Cutoff </label>
        <input type='text' placeholder="0.01" name='fdr_cutoff'/>
      </div>

    </fieldset>

    <input type="submit" value='Save' class="btn btn-primary finish"/>

  </div>


</div>



%rebase templates/layout
