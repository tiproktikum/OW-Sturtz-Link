unit uTypes;

interface

type
  TGroupOrder = record
    Id: Integer;
    Name: string;
    FolderName: string;
  end;

  TOptimizedItem = record
    OptimizedId: Integer;
    GrOrderId: Integer;
    ItemId: Integer;
    Articul: string;
    Name: string;
    OutColor: string;
    InColor: string;
    Qty: Integer;
    Length: Double;
    Ostat: Double;
    SumProf: Double;
    IsForPair: Integer;
    ItemType: Integer;
    LongRaspil: Double;
  end;

  TOptimizedDetail = record
    DetailId: Integer;
    OptimizedId: Integer;
    PartNo: Integer;
    Length: Double;
    Qty: Integer;
    Ug1: Double;
    Ug2: Double;
    OrderId: Integer;
    WindowId: Integer;
    Num: Integer;
    SubNum: Integer;
  end;

  TGroupOrderRef = class
  public
    Id: Integer;
    Name: string;
    constructor Create(AId: Integer; const AName: string);
  end;

implementation

constructor TGroupOrderRef.Create(AId: Integer; const AName: string);
begin
  Id := AId;
  Name := AName;
end;

end.
