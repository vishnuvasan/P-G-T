<br /> <br />
% if errors and len( errors ) > 0:
  % for error in errors:
    <div class='alert alert-danger'>
      {{ error }}
    </div>
  % end
% end
