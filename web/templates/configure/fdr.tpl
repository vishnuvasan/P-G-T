  % include templates/includes/error.tpl

  <form method='POST'>

    <div class="control-group">
      <label for="" class="control-label"> Enable MSGF+</label>
      <div class="controls">
        <div class="slide-checkbox">  
          <input type="checkbox" value="on" id="checkbox1" name="use_concatenated_decoy" class="on-off" {{ 'checked' if config[kind]['use_concatenated_decoy'] else '' }} />
          <label for="checkbox1"></label>
        </div>
      </div>
    </div>

    <div class="control-group">
      <label> FDR Cutoff: <span id='fdr-cutoff-display' class='text-info lead'> {{ config[kind]['fdr_cutoff'] }}% </span> </label>
      <div class="value-slider" data-min="0" data-max="100" data-value="{{ config[kind]['fdr_cutoff'] }}" data-callback='fdr_cutoff'></div>
      <input type='hidden' name='fdr_cutoff' id='fdr_cutoff' value='{{ config[kind]['fdr_cutoff'] }}' />
    </div>

    % include templates/includes/submit.tpl

  </form>

%rebase templates/layout kind=kind, is_config=True

