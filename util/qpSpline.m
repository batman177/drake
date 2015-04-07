function [coefs, ts, objval] = qpSpline(ts, xs, xd0, xdf, settings, debug)
% Compute a smooth spline through four knot points with fixed velocity at the
% initial and final knots only. Solves a (very small) QP using cvxgen to
% minimize the integral of the squared norm of acceleration along the
% trajectory.
% @param ts [1x4] times
% @param xs [6x4] 6-DOF poses at each knot
% @param xd0 [6x1] initial velocity
% @param xdf [6x1] final velocity
% @param settings settings struct; options
%   - optimize_knot_times @default false
% @option debug

if ~isfield(settings, 'optimize_knot_times')
  settings.optimize_knot_times = false;
end

if nargin < 6
  debug = false;
end

assert(all(size(ts) == [1,4]));
assert(all(size(xs) == [6,4]));
assert(all(size(xd0) == [6,1]));
assert(all(size(xdf) == [6,1]));

params = struct('x0', xs(:,1),...
                'xd0', xd0,...
                'x1', xs(:,2),...
                'x2', xs(:,3),...
                'xf', xs(:,4),...
                'xdf', xdf,...
                't0', ts(1),...
                't1', ts(2),...
                't2', ts(3),...
                'tf', ts(4),...
                'Q0', [2^2 * (ts(2) - ts(1)), 6*(ts(2) - ts(1))^2;
                       6*(ts(2) - ts(1))^2, 6^2 / 3 *(ts(2) - ts(1))^3],...
                'Q1', [2^2 * (ts(3) - ts(2)), 6*(ts(3) - ts(2))^2;
                       6*(ts(3) - ts(2))^2, 6^2 / 3 *(ts(3) - ts(2))^3],...
                'Q2', [2^2 * (ts(4) - ts(3)), 6*(ts(4) - ts(3))^2;
                       6*(ts(4) - ts(3))^2, 6^2 / 3 *(ts(4) - ts(3))^3]);
cvx_settings = struct('verbose', 0);

if settings.optimize_knot_times
  [vars, status] = qpSplineGridSearchmex(params, cvx_settings);
  ts(2) = vars.t1;
  ts(3) = vars.t2;
else
  [vars, status] = qpSplineMex(params, cvx_settings);
end
coefs = [cat(3, vars.C0_3, vars.C0_2, vars.C0_1, vars.C0_0),...
         cat(3, vars.C1_3, vars.C1_2, vars.C1_1, vars.C1_0),...
         cat(3, vars.C2_3, vars.C2_2, vars.C2_1, vars.C2_0)];
objval = status.optval;

if debug
  pp = mkpp(ts, coefs, 6);

  tt = linspace(ts(1), ts(end), 1000);
  ps = ppval(pp, tt);
  figure(15);
  clf
  for j = 1:6
    subplot(6, 1, j)
    hold on
    plot(tt, ps(j,:));
    plot(ts, xs(j,:), 'ro');
  end

  atraj = fnder(pp, 2);
  as = ppval(atraj, tt);
  ns = sum(as.^2,1);
  error = abs(sum(ns) * (tt(2) - tt(1)) - status.optval) / status.optval

  figure(16);
  clf
  vs = ppval(fnder(pp, 1), tt);
  for j = 1:6
    subplot(6, 1, j)
    plot(tt, vs(j,:));
  end

  figure(17);
  clf
  for j = 1:6
    subplot(6,1,j);
    plot(tt, as(j,:));
  end

  rangecheck(error, 0, 1e-2);
end