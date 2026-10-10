unit DPH.Storage.Types;

interface

uses System.SysUtils;

type
  EDPHStorage = class(Exception);

  TDPHManifestFile = record
    RelativePath: string;
    SHA256: string;
    SizeBytes: Int64;
    Kind: string;
    Encoding: string;
    Availability: string;
  end;
  TDPHManifest = TArray<TDPHManifestFile>;

  TDPHProjectStatus = record
    PublishedGeneration: Int64;
    ModificationDetected: Boolean;
    AnalysisStale: Boolean;
    KnowledgeReviewNeeded: Boolean;
    AnalysisFailed: Boolean;
    ReassessmentRequested: Boolean;
  end;

implementation
end.
