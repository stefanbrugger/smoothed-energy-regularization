%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%  Smoothed Quadratic Energies on Meshes
%%  ACM TOG - J. Martinez Esturo, C. Rössl, and H. Theisel
%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

classdef Deform2DConformal < Deform2D
  %DEFOR2DMCONFORMAL

  properties
    se = []
    constrSolver = []
  end

  methods
    function obj = Deform2DConformal(mesh, beta)
      %% Constructor
      obj = obj@Deform2D(mesh, beta);

      obj.name = 'ASAP';
    end

    function init(obj, hidxs)
      mesh = obj.mesh;

      %% Setup material behaviour term
      % conformal <=> as-similar-as-possible
      Mwq = eye(4) - 0.5 .* [1, 0, 0,1;
                             0, 1,-1,0;
                             0,-1, 1,0;
                             1, 0, 0,1];

      Mq = blockfill(4,4,mesh.nt,repmat(Mwq,1,mesh.nt));

      %% Setup integrated / smoothed system
      E  = Mq*mesh.GGP;

      en = size(E,1) / mesh.nt;

      obj.se = obj.smootherf(mesh,obj.beta, en, 2,1);
      obj.se.updateLHS(E);

      %% Setup solver

      % constrained handle indices
      obj.hidxs = hidxs;
      cidxs = reshape([(hidxs-1)*2+1; (hidxs-1)*2+2],1,[]);

      obj.constrSolver = obj.csolverf(obj.se.AAs,cidxs,obj.se.bbs);
    end

    function [converged,u] = deform(obj, hcoords, ~)
      converged = true; u = [];
      if(isempty(obj.hidxs)), return; end

      mesh = obj.mesh;

      u = obj.constrSolver.solve(reshape(hcoords,[],1));

      mesh.p = reshape(u,2,[]);
    end

  end

end
