unit uTranslit;

interface

{ Транслитерация кириллицы в латиницу (ГОСТ 7.79-2000, система B).
  Станок Stürtz не поддерживает кириллицу; все выгружаемые в .sob/.soe и имена файлов выгрузки должны проходить через эту функцию. }
function CyrillicToLatin(const S: string): string;

implementation

function CyrillicToLatin(const S: string): string;
const
  // ГОСТ 7.79-2000 (система B): одна кириллическая буква -> латинская
  Map: array [0..65, 0..1] of string = (
    ('А','A'),('Б','B'),('В','V'),('Г','G'),('Д','D'),('Е','E'),('Ё','Jo'),('Ж','Zh'),('З','Z'),
    ('И','I'),('Й','J'),('К','K'),('Л','L'),('М','M'),('Н','N'),('О','O'),('П','P'),('Р','R'),
    ('С','S'),('Т','T'),('У','U'),('Ф','F'),('Х','H'),('Ц','C'),('Ч','Ch'),('Ш','Sh'),('Щ','Shh'),
    ('Ъ',''''),('Ы','Y'),('Ь',''''),('Э','E'),('Ю','Ju'),('Я','Ja'),
    ('а','a'),('б','b'),('в','v'),('г','g'),('д','d'),('е','e'),('ё','jo'),('ж','zh'),('з','z'),
    ('и','i'),('й','j'),('к','k'),('л','l'),('м','m'),('н','n'),('о','o'),('п','p'),('р','r'),
    ('с','s'),('т','t'),('у','u'),('ф','f'),('х','h'),('ц','c'),('ч','ch'),('ш','sh'),('щ','shh'),
    ('ъ',''''),('ы','y'),('ь',''''),('э','e'),('ю','ju'),('я','ja')
  );
var
  I, J: Integer;
  C: string;
  Found: Boolean;
begin
  Result := '';
  for I := 1 to Length(S) do
  begin
    Found := False;
    for J := 0 to High(Map) do
      if Map[J, 0] = S[I] then
      begin
        Result := Result + Map[J, 1];
        Found := True;
        Break;
      end;
    if not Found then
      Result := Result + S[I];
  end;
end;

end.
