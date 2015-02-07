<div class="control-group">
  <label class='control-label'> {{ title }} </label>

  % for i in range( len( labels )):
    <label class="radio inline">
      <input type="radio" checked="" value="{{ values[ i ] }}"  name="{{ name }}">
      <span class="overlay"></span> {{ labels[ i ] }} 
    </label>
  % end

</div>
