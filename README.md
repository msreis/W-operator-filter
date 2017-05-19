# W-operator-filter

A set of programs to design and apply W-operator filters on noisy binary images.


src/parse_image.pl:

  Creates the pair of binary ideal/observed images, as well as the samples of
  different windows screened through them. The observed images are filled with
  an uniformely distributed salt-and-pepper noise.


src/design_W_operator.pl:
  
  Given a minimum subset obtained through the execution of feature selection on
  a sample of a window of size n, designs a W-operator of size n.

  Example of a feature selection procedure using the featsel framework
  (which is available at https://github.com/msreis/featsel):

  ./featsel -a es -n 3 -m 8 -c mce -f output/dat/sample_01_W_03.dat

  The feature selection procedure above yields a characteristic vector of the
  best subset of features to be used in the W-operator design - such vector
  should be used as argument in the design_W_operator.pl program.


src/filter_image.pl:

  Uses a W-operator designed using design_W_operator.pl to screen the observed
  image of parse_image.pl, hence obtaining an image that has its salt-and-pepper
  noise filtered.


test/integration_test.t:

  Integration tests for all the programs above.



