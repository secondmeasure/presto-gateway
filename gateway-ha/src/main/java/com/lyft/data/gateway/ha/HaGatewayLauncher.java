package com.lyft.data.gateway.ha;

import com.google.inject.Injector;
import com.lyft.data.baseapp.BaseApp;
import com.lyft.data.gateway.ha.config.HaGatewayConfiguration;
import io.dropwizard.assets.AssetsBundle;
import io.dropwizard.setup.Bootstrap;
import io.dropwizard.setup.Environment;
import io.dropwizard.views.ViewBundle;
import io.prometheus.client.CollectorRegistry;
import io.prometheus.client.dropwizard.DropwizardExports;
import io.prometheus.client.exporter.MetricsServlet;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class HaGatewayLauncher extends BaseApp<HaGatewayConfiguration> {
  private static final Logger logger = LoggerFactory.getLogger(HaGatewayLauncher.class);

  public HaGatewayLauncher(String... basePackages) {
    super(basePackages);
  }

  @Override
  public void initialize(Bootstrap<HaGatewayConfiguration> bootstrap) {
    super.initialize(bootstrap);
    bootstrap.addBundle(new ViewBundle<>());
    bootstrap.addBundle(new AssetsBundle("/assets", "/assets", null, "assets"));
  }

  @Override
  protected void applicationAtRun(HaGatewayConfiguration configuration,
                                  Environment environment,
                                  Injector injector) {
    // Register prometheus metrics
    logger.info("Registering prometheus metrics endpoint at /prometheusMetrics");
    CollectorRegistry collectorRegistry = new CollectorRegistry();
    collectorRegistry.register(new DropwizardExports(environment.metrics()));
    environment.admin()
            .addServlet("prometheusMetrics", new MetricsServlet(collectorRegistry))
            .addMapping("/prometheusMetrics");
  }

  public static void main(String[] args) throws Exception {
    /** base package is scanned for any Resource class to be loaded by default. */
    String basePackage = "com.lyft";
    new HaGatewayLauncher(basePackage).run(args);
  }
}
